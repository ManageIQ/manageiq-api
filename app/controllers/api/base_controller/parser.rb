module Api
  class BaseController
    module Parser
      def parse_api_request
        @req = RequestAdapter.new(request, params)
      end

      def validate_api_request
        validate_optional_collection_classes

        # API Version Validation
        if @req.version
          vname = @req.version
          unless Api::SUPPORTED_VERSIONS.include?(vname)
            raise BadRequestError, "Unsupported API Version #{vname} specified"
          end
        end

        cname, ctype = validate_api_request_collection
        cname, ctype = validate_api_request_subcollection(cname, ctype)

        # Method Validation for the collection or sub-collection specified
        if cname && ctype
          mname = @req.method
          unless collection_config.supports_http_method?(cname, mname) || ignore_http_method_validation? || mname == :options
            raise BadRequestError, "Unsupported HTTP Method #{mname} for the #{ctype} #{cname} specified"
          end
        end
      end

      def validate_optional_collection_classes
        @collection_klasses = {} # Default all to config classes
        validate_collection_class
      end

      def validate_api_action
        return if @req.collection.blank? || ignore_http_method_validation?
        case @req.method
        when :post
          type, target = request_type_target
          validate_post_api_action(@req.subject, @req.method, type, target)
        when :get
          validate_method_action(:get, "read")
        when :patch, :put
          validate_method_action(:post, "edit")
        when :delete
          validate_method_action(:post, "delete")
        when :options
          validate_option_method_action
        else
          raise "invalid action"
        end
      end

      def ensure_supports(type, model, action, supports = action)
        unless model.supports?(supports)
          # for class level methods (like create) we display the type, otherwise we display the instance information
          instance_name = model.kind_of?(Class) ? type.to_s.titleize : model_ident(model, type)
          raise BadRequestError, "#{action.to_s.titleize} for #{instance_name}: #{model.unsupported_reason(supports)}"
        end
      end

      def ensure_respond_to(type, model, action, respond_to)
        raise BadRequestError, "#{action.to_s.titleize} not supported for #{model_ident(model, type)}" unless model.respond_to?(respond_to)
      end

      def parse_id(resource, collection)
        return nil if !resource.kind_of?(Hash) || resource.blank?

        href_id = href_id(resource["href"], collection)
        case
        when href_id.present?
          href_id
        when resource["id"].kind_of?(Integer)
          resource["id"]
        when resource["id"].kind_of?(String)
          resource["id"].to_i
        end
      end

      def href_id(href, collection)
        if href.present? && href.match(%r{^.*/#{collection}/(\d+)$})
          Regexp.last_match(1).to_i
        end
      end

      def parse_by_attr(resource, type, attr_list = [])
        klass = collection_class(type)
        attr_list |= %w(guid) if klass.attribute_method?(:guid)
        attr_list |= String(collection_config[type].identifying_attrs).split(",")
        objs = attr_list.map { |attr| klass.find_by(attr => resource[attr]) if resource[attr] }.compact
        objs.collect(&:id).first
      end

      def parse_owner(resource)
        return nil if resource.blank?
        parse_id(resource, :users) || parse_by_attr(resource, :users)
      end

      def parse_group(resource)
        return nil if resource.blank?
        parse_id(resource, :groups) || parse_by_attr(resource, :groups)
      end

      def parse_role(resource)
        return nil if resource.blank?
        parse_id(resource, :roles) || parse_by_attr(resource, :roles)
      end

      def parse_tenant(resource)
        parse_id(resource, :tenants) unless resource.blank?
      end

      def parse_ownership(data)
        {
          :owner => collection_class(:users).find_by(:id => parse_owner(data["owner"])),
          :group => collection_class(:groups).find_by(:id => parse_group(data["group"]))
        }.compact if data.present?
      end

      # RBAC Aware type specific resource fetches

      def parse_fetch_group(data)
        if data
          group_id = parse_group(data)
          raise BadRequestError, "Missing Group identifier href, id or description" if group_id.nil?
          resource_search(group_id, :groups)
        end
      end

      def parse_fetch_role(data)
        if data
          role_id = parse_role(data)
          raise BadRequestError, "Missing Role identifier href, id or name" if role_id.nil?
          resource_search(role_id, :roles)
        end
      end

      def parse_fetch_tenant(data)
        if data
          tenant_id = parse_tenant(data)
          raise BadRequestError, "Missing Tenant identifier href or id" if tenant_id.nil?
          resource_search(tenant_id, :tenants)
        end
      end

      private

      def ignore_http_method_validation?
        @req.subcollection == 'settings'
      end

      def validate_deprecation
        api_log_warn("Collection '%s' is deprecated" % @req.collection) if collection_option?(:deprecated)
        api_log_warn("Subcollection '%s' is deprecated" % @req.subcollection) if @req.subcollection? && collection_config.option?(@req.subcollection, :deprecated)
      end

      def validate_method_action(method_name, action_name)
        validate_deprecation
        cname, target = if collection_option?(:arbitrary_resource_path)
                          [@req.collection, (@req.collection_id ? :resource : :collection)]
                        else
                          [@req.subject, request_type_target.last]
                        end

        aspec = lookup_aspec(cname, target)
        return if method_name == :get && aspec.nil?
        action_hash = fetch_action_hash(aspec, method_name, action_name)
        unless api_user_role_allows?(action_hash[:identifier])
          raise ForbiddenError, "Use of the #{action_name} action is forbidden"
        end
      end

      def request_type_target
        if @req.subcollection
          @req.subcollection_id ? [:resource, :subresource] : [:collection, :subcollection]
        else
          @req.collection_id ? [:resource, :resource] : [:collection, :collection]
        end
      end

      def validate_post_api_action(cname, mname, type, target)
        aname = @req.action

        aspec = if @req.subcollection?
                  collection_config.typed_subcollection_actions(@req.collection, cname, target) ||
                    collection_config.typed_collection_actions(cname, target)
                else
                  collection_config.typed_collection_actions(cname, target)
                end
        raise BadRequestError, "No actions are supported for #{cname} #{type}" unless aspec

        action_hash = fetch_action_hash(aspec, mname, aname)
        if action_hash.blank?
          unless type == :resource && collection_config.custom_actions?(cname)
            raise BadRequestError, "Unsupported Action #{aname} for the #{cname} #{type} specified"
          end
        end

        if action_hash.present?
          unless api_user_role_allows?(action_hash[:identifier])
            raise ForbiddenError, "Use of Action #{aname} is forbidden"
          end
        end

        validate_post_api_action_as_subcollection(cname, mname, aname)
      end

      def validate_option_method_action
        # not currently validating options for the default create or update
        return unless @req.option_action

        cname = @req.subject
        mname = :post
        aname = @req.option_action
        _type, target = request_type_target

        aspec = lookup_aspec(cname, target)
        action_hash = fetch_action_hash(aspec, mname, aname)
        raise BadRequestError, "Unsupported Option #{aname} for the #{cname} collection" if action_hash.blank?
      end

      def validate_api_request_collection
        # Collection Validation
        if @req.collection
          cname = @req.collection
          ctype = "Collection"
          raise BadRequestError, "Unsupported #{ctype} #{cname} specified" unless collection_config[cname]
          if collection_config.primary?(cname)
            if "#{@req.collection_id}#{@req.subcollection}#{@req.subcollection_id}".present?
              raise BadRequestError, "Invalid request for #{ctype} #{cname} specified"
            end
          else
            raise BadRequestError, "Unsupported #{ctype} #{cname} specified" unless collection_config.collection?(cname)
          end
          [cname, ctype]
        end
      end

      def validate_api_request_subcollection(cname, ctype)
        # Sub-Collection Validation for the specified Collection
        if cname && @req.subcollection
          return [cname, ctype] if @req.subcollection == 'settings' && collection_option?(:settings)
          return [cname, ctype] if collection_option?(:arbitrary_resource_path)
          return [cname, ctype] if request_is_for_resource_entity?

          ctype = "Sub-Collection"
          unless collection_config.subcollection?(cname, @req.subcollection)
            raise BadRequestError, "Unsupported #{ctype} #{@req.subcollection} specified"
          end
          cname = @req.subcollection
        end
        [cname, ctype]
      end

      def validate_post_api_action_as_subcollection(cname, mname, aname)
        return if cname == @req.collection
        return if collection_config.subcollection_denied?(@req.collection, cname)

        aspec = collection_config.typed_subcollection_actions(@req.collection, cname, @req.subcollection_id ? :subresource : :subcollection)
        return unless aspec

        action_hash = fetch_action_hash(aspec, mname, aname)
        raise BadRequestError, "Unsupported Action #{aname} for the #{cname} sub-collection" if action_hash.blank?

        unless api_user_role_allows?(action_hash[:identifier])
          raise ForbiddenError, "Use of Action #{aname} for the #{cname} sub-collection is forbidden"
        end
      end

      def fetch_action_hash(aspec, method_name, action_name)
        Array(aspec[method_name]).detect { |h| h[:name] == action_name } || {}
      end

      def collection_option?(option)
        collection_config.option?(@req.collection, option) if @req.collection
      end

      def assert_id_not_specified(data, type)
        if data.key?('id') || data.key?('href')
          raise BadRequestError, "Resource id or href should not be specified for creating a new #{type}"
        end
      end

      def assert_all_required_fields_exists(data, type, required_fields)
        missing_fields = required_fields - data.keys
        unless missing_fields.empty?
          raise BadRequestError, "Resource #{missing_fields.join(", ")} must be specified when creating a new #{type}"
        end
      end

      def validate_collection_class
        param = params['collection_class']
        return unless param.present?

        klass = collection_class(@req.collection)
        return if param == klass.name

        param_klass = klass.descendants.detect { |sub_klass| param == sub_klass.name }
        if param_klass.present?
          @collection_klasses[@req.collection.to_sym] = param_klass
          return
        end

        raise BadRequestError, "Invalid collection_class #{param} specified for the #{@req.collection} collection"
      end

      def request_is_for_resource_entity?
        collection_config.resource_entity?(@req.collection, @req.subcollection) && @req.subcollection_id.blank?
      end

      def lookup_aspec(cname, target)
        if request_is_for_resource_entity?
          collection_config.resource_entity_actions(@req.collection, @req.subcollection)
        elsif @req.subcollection?
          collection_config.typed_subcollection_actions(@req.collection, cname, target) ||
            collection_config.typed_collection_actions(cname, target)
        else
          collection_config.typed_collection_actions(cname, target)
        end
      end
    end
  end
end
