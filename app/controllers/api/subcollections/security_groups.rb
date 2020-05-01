module Api
  module Subcollections
    module SecurityGroups
      def security_groups_query_resource(object)
        object.respond_to?(:security_groups) ? object.security_groups : {}
      end

      def security_groups_add_resource(parent, _type, _id, data)
        security_group = data["name"]
          raise "Cannot add #{security_group} to #{parent.name}" unless parent.supports_add_security_group?

          message = "Adding security group #{security_group} to #{parent.name}"
          task_id = queue_object_action(parent, message, :method_name => "add_security_group", :args => [security_group])
          action_result(true, message, :task_id => task_id)
        rescue => e
          action_result(false, e.to_s)
        end
      end

      def security_groups_remove_resource(parent, _type, _id, data)
        security_group = data["name"]
        begin
          raise "Cannot remove #{security_group} from #{parent.name}" unless parent.supports_remove_security_group?

          message = "Removing security group #{security_group} from #{parent.name}"
          task_id = queue_object_action(parent, message, :method_name => "remove_security_group", :args => [security_group])
          action_result(true, message, :task_id => task_id)
        rescue => e
          action_result(false, e.to_s)
        end
      end

      def security_groups_create_resource(provider, _type, _id, data)
        data.deep_symbolize_keys!
        raise 'Must specify a name for the security group' unless data[:name]

        message = "Creating security group"
        task_id = queue_object_action(provider, message, :method_name => "create_security_group", :args => [data])
        action_result(true, message, :task_id => task_id)
      rescue => e
        action_result(false, e.to_s)
      end

      def security_groups_edit_resource(_object, type, resource_id = nil, data = {})
        data.deep_symbolize_keys!
        raise BadRequestError, "Must specify an id for updating a #{type} resource" unless resource_id

        security_group = resource_search(resource_id, type, collection_class(type))
        task_id = security_group.update_security_group_queue(User.current_user.userid, data)
        action_result(true, "Updating #{security_group.name}", :task_id => task_id)
      end

      def security_groups_delete_resource(_parent, type, resource_id, _data)
        delete_resource(type, resource_id, data)
      end
    end
  end
end
