module Api
  class BaseController
    module Validator
      def validate_api_version
        if @req.version
          unless Api::SUPPORTED_VERSIONS.include?(@req.version)
            raise BadRequestError, "Unsupported API Version #{@req.version} specified"
          end
        end
      end

      def validate_request_method
        if collection_name && type
          unless target_collection_config.verbs&.include?(@req.method) || @req.method == :options
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
        return if @req.method == :get && action_spec.nil?
        raise BadRequestError, "Disabled action #{@req.action}" if action_hash[:disabled]
        unless api_user_role_allows?(action_hash[:identifier])
          raise ForbiddenError, "Use of the #{@req.action} action is forbidden"
        end
      end

      def validate_post_method
        raise BadRequestError, "No actions are supported for #{collection_name} #{type}" unless action_spec

        if action_hash.blank?
          unless type == :resource && collection_options.include?(:custom_actions)
            raise BadRequestError, "Unsupported Action #{@req.action} for the #{collection_name} #{type} specified"
          end
        end

        raise BadRequestError, "Disabled Action #{@req.action} for the #{collection_name} #{type} specified" if action_hash[:disabled]
        raise ForbiddenError, "Use of Action #{@req.action} is forbidden" unless api_user_role_allows?(action_hash[:identifier])

        if target == :collection && @req.resources.all?(&:empty?)
          raise BadRequestError, "No #{collection_name} resources were specified for the #{@req.action} action"
        end
      end

      def validate_api_request_collection
        return unless @req.collection
        raise BadRequestError, "Unsupported Collection #{@req.collection} specified" unless target_collection_config
        if primary_collection?
          if "#{@req.collection_id}#{@req.subcollection}#{@req.subcollection_id}".present?
            raise BadRequestError, "Invalid request for Collection #{@req.collection} specified"
          end
        else
          raise BadRequestError, "Unsupported Collection #{@req.collection} specified" unless collection_config.collection?(@req.collection)
        end
      end

      def validate_api_request_subcollection
        # Sub-Collection Validation for the specified Collection
        if target == :subcollection && !arbitrary_resource_path?
          unless collection_config.subcollection?(@req.collection, @req.subcollection)
            raise BadRequestError, "Unsupported Sub-Collection #{@req.subcollection} specified"
          end
        end
      end

      def validate_post_api_action_as_subcollection
        return if collection_name == @req.collection
        return if collection_config.subcollection_denied?(@req.collection, collection_name)
        return unless action_spec

        raise BadRequestError, "Unsupported Action #{@req.action} for the #{collection_name} sub-collection" if action_hash.blank?
        raise BadRequestError, "Disabled Action #{@req.action} for the #{collection_name} sub-collection" if action_hash[:disabled]
        raise ForbiddenError, "Use of Action #{@req.action} for the #{collection_name} sub-collection is forbidden" unless api_user_role_allows?(action_hash[:identifier])
      end

      private

      def target_collection_config
        @target_collection_config ||= collection_config[@req.subject] || collection_config[@req.collection]
      end

      def collection_name
        @collection_name ||= if @req.collection && arbitrary_resource_path?
                               @req.collection
                             else
                               @req.subject
                             end
      end

      def collection_options
        @ocollection_options ||= target_collection_config.options || []
      end

      def primary_collection?
        @primary_collection ||= collection_config.primary?(collection_name)
      end

      def arbitrary_resource_path?
        @arbitrary ||= collection_options.include?(:arbitrary_resource_path)
      end

      def action_spec
        @action_spec ||= if @req.subcollection
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
        @action_hash = Array(action_spec[method]).detect { |h| h[:name] == @req.action } || {}
      end

      def type
        @type ||= if (@req.collection_id && !@req.subcollection) || (@req.subcollection && @req.subcollection_id)
                    :resource
                  else
                    :collection
                  end
      end

      def target
        @target ||= if @req.subcollection && !arbitrary_resource_path?
                      @req.subcollection_id ? :subresource : :subcollection
                    else
                      @req.collection_id ? :resource : :collection
                    end
      end
    end
  end
end
