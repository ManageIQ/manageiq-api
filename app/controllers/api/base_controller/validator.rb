module Api
  class BaseController
    module Validator
      def validate_api_version
        if @req.version
          vname = @req.version
          unless Api::SUPPORTED_VERSIONS.include?(vname)
            raise BadRequestError, "Unsupported API Version #{vname} specified"
          end
        end
      end

      def validate_request_method
        if collection_name && type
          unless collection_config.supports_http_method?(collection_name, @req.method) || @req.method == :options
            raise BadRequestError, "Unsupported HTTP Method #{@req.method} for the #{type} #{collection_name} specified"
          end
        end
      end

      def validate_optional_collection_classes
        @collection_klasses = {} # Default all to config classes
        param = params['collection_class']
        return if param.blank?

        klass = collection_class(@req.collection)
        return if param == klass.name

        param_klass = klass.descendants.detect { |sub_klass| param == sub_klass.name }
        if param_klass.present?
          @collection_klasses[@req.collection.to_sym] = param_klass
          return
        end

        raise BadRequestError, "Invalid collection_class #{param} specified for the #{@req.collection} collection"
      end

      def validate_api_action
        return unless @req.collection
        return if @req.method == :get && aspec.nil?
        raise BadRequestError, "Disabled action #{@req.action}" if action_hash[:disabled]
        unless api_user_role_allows?(action_hash[:identifier])
          raise ForbiddenError, "Use of the #{@req.action} action is forbidden"
        end
      end

      def validate_post_method
        return unless method == :post
        raise BadRequestError, "No actions are supported for #{collection_name} #{type}" unless aspec

        if action_hash.blank?
          unless type == :resource && req_collection_config&.options&.include?(:custom_actions)
            raise BadRequestError, "Unsupported Action #{@req.action} for the #{collection_name} #{type} specified"
          end
        end

        if action_hash.present?
          raise BadRequestError, "Disabled Action #{@req.action} for the #{collection_name} #{type} specified" if action_hash[:disabled]
          unless api_user_role_allows?(action_hash[:identifier])
            raise ForbiddenError, "Use of Action #{@req.action} is forbidden"
          end
        end

        validate_post_api_action_as_subcollection
      end

      def validate_api_request_collection
        return unless @req.collection
        raise BadRequestError, "Unsupported Collection #{@req.collection} specified" unless collection_config[@req.collection]
        if primary_collection?
          if "#{@req.collection_id}#{@req.subcollection}#{@req.subcollection_id}".present?
            raise BadRequestError, "Invalid @req for Collection #{@req.collection} specified"
          end
        else
          raise BadRequestError, "Unsupported Collection #{@req.collection} specified" unless collection_config.collection?(@req.collection)
        end
      end

      def validate_api_request_subcollection
        # Sub-Collection Validation for the specified Collection
        if @req.collection && @req.subcollection && !arbitrary_resource_path?
          unless collection_config.subcollection?(@req.collection, @req.subcollection)
            raise BadRequestError, "Unsupported Sub-Collection #{@req.subcollection} specified"
          end
        end
      end

      def validate_post_api_action_as_subcollection
        return if collection_name == @req.collection
        return if collection_config.subcollection_denied?(@req.collection, collection_name)
        return unless aspec

        raise BadRequestError, "Unsupported Action #{@req.action} for the #{collection_name} sub-collection" if action_hash.blank?
        raise BadRequestError, "Disabled Action #{@req.action} for the #{collection_name} sub-collection" if action_hash[:disabled]

        unless api_user_role_allows?(action_hash[:identifier])
          raise ForbiddenError, "Use of Action #{@req.action} for the #{collection_name} sub-collection is forbidden"
        end
      end

      private

      def req_collection_config
        @req_collection_config ||= collection_config[@req.collection]
      end

      def collection_name
        @collection_name ||= if @req.collection && arbitrary_resource_path?
                               @req.collection
                             else
                               @req.subject
                             end
      end

      def arbitrary_resource_path?
        @arbitrary ||= req_collection_config&.options&.include?(:arbitrary_resource_path)
      end

      def primary_collection?
        @primary_collection ||= collection_config.primary?(collection_name)
      end

      def subcollection
        @subcollection ||= @req.subcollection
      end

      def aspec
        @aspec ||= if @req.subcollection
                     collection_config.typed_subcollection_actions(@req.collection, collection_name, target) || collection_config.typed_collection_actions(collection_name, target)
                   else
                     collection_config.typed_collection_actions(collection_name, target)
                   end
      end

      def method
        @method ||= if @req.method == :put || @req.method == :patch
                      :post
                    else
                      @req.method
                    end
      end

      def action_hash
        @action_hash = Array(aspec[method]).detect { |h| h[:name] == @req.action } || {}
      end

      def type
        @type ||= if (@req.collection_id && !@req.subcollection) || (@req.subcollection && @req.subcollection_id)
                    :resource
                  else
                    :collection
                  end
      end

      def target
        @target ||= if @req.subcollection && !req_collection_config.options&.include?(:arbitrary_resource_path)
                      @req.subcollection_id ? :subresource : :subcollection
                    else
                      @req.collection_id ? :resource : :collection
                    end
      end
    end
  end
end
