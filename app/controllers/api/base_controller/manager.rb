module Api
  class BaseController
    module Manager
      def update_collection(type, id)
        case @req.method
        when :put
          return edit_resource(type, id, @req.json_body)
        when :patch
          return patch_resource(type, id)
        end

        unless id || @req.subcollection? || @req.json_body.key?("resources")
          collection_target = "#{@req.action}_collection"
          return send(collection_target, type, @req.json_body.except("action")) if respond_to?(collection_target)
        end

        action = @req.action
        target = target_resource_method(type, action)
        raise BadRequestError,
              "Unimplemented Action #{action} for #{type} resources" unless respond_to?(target)

        if id
          update_one_collection(@req.subcollection?, target, type, id, @req.resource)
        else
          update_multiple_collections(@req.subcollection?, target, type, @req.resources)
        end
      end

      def parent_resource_obj
        type = @req.collection.to_sym
        resource_search(@req.collection_id, type, collection_class(type))
      end

      def collection_class(type)
        @collection_klasses[type.to_sym] || collection_config.klass(type)
      end

      #
      # Patching a resource, post syntax
      #
      # [
      #   {
      #     "action" : "add" | "edit" | "remove"
      #     "path" : "attribute_name",
      #     "value" : "value to add or edit"
      #   }
      #   ...
      # ]
      #
      def patch_resource(type, id)
        patched_attrs = {}
        return edit_resource(type, id, @req.json_body) if @req.json_body.kind_of?(Hash)
        @req.json_body.each do |patch_cmd|
          action = patch_cmd["action"]
          path   = patch_cmd["path"]
          value  = patch_cmd["value"]
          if action.nil?
            api_log_info("Must specify an attribute action for each path command for the resource #{type}/#{id}")
          elsif path.nil?
            api_log_info("Must specify an attribute path for each patch method action for the resource #{type}/#{id}")
          elsif path.split('/').size > 1
            api_log_info("Can only patch attributes of the resource #{type}/#{id}")
          else
            attr = path.split('/')[0]
            patched_attrs[attr] = value if %w(edit add).include?(action)
            patched_attrs[attr] = nil if action == "remove"
          end
        end
        edit_resource(type, id, patched_attrs)
      end

      def delete_subcollection_resource(type, id)
        parent_resource = parent_resource_obj
        typed_target    = "delete_resource_#{type}"
        raise BadRequestError,
              "Cannot delete subcollection resources of type #{type}" unless respond_to?(typed_target)

        resource = @req.json_body["resource"]
        resource = {"href" => "#{@req.base}#{@req.path}"} if !resource || resource.empty?
        send(typed_target, parent_resource, type, id.to_i, resource)
      end

      private

      def target_resource_method(type, action)
        if @req.subcollection?
          "#{type}_#{action}_resource"
        else
          target = "#{action}_resource"
          return target if respond_to?(target)
          collection_config.custom_actions?(type) ? "custom_action_resource" : "undefined_api_method"
        end
      end

      def update_one_collection(is_subcollection, target, type, id, resource)
        id = id.to_i if id.kind_of?(String) && id =~ /\A\d+\z/
        parent_resource = parent_resource_obj if is_subcollection
        if is_subcollection
          send(target, parent_resource, type, id, resource)
        else
          send(target, type, id, resource)
        end
      end

      def update_multiple_collections(is_subcollection, target, type, resources)
        action = @req.action

        processed = 0
        results = resources.each.collect do |r|
          next if r.blank?

          rid = parse_id(r, type)
          create_or_add_action = %w(create add).include?(action)
          if rid && create_or_add_action
            raise BadRequestError, "Resource id or href should not be specified for creating a new #{type}"
          elsif !rid && !create_or_add_action
            rid = parse_by_attr(r, type)
          end
          r.except!(*ID_ATTRS) if rid
          processed += 1
          update_one_collection(is_subcollection, target, type, rid, r)
        end.flatten
        raise BadRequestError, "No #{type} resources were specified for the #{action} action" if processed == 0
        {"results" => results}
      end
    end
  end
end
