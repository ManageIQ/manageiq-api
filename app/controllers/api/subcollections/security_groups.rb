module Api
  module Subcollections
    module SecurityGroups
      def security_groups_query_resource(object)
        object.respond_to?(:security_groups) ? Array(object.security_groups) : []
      end

      def security_groups_create_resource(parent, _type, _id, data)
        security_group = data["name"]

        begin
          raise "Cannot add #{security_group} to #{parent.name}" unless parent.supports_create_security_group?
          message = "Adding security group #{security_group} to #{parent.name}"
          user_id = User.current_user.id
          task_id = queue_object_action(parent, message, :method_name => "create_security_group", :args => [data, user_id])
          action_result(true, message, :task_id => task_id)
        rescue => e
          action_result(false, e.to_s)
        end
      end

      def security_groups_add_resource(parent, _type, _id, data)
        security_group = data["name"]

        begin
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
    end
  end
end
