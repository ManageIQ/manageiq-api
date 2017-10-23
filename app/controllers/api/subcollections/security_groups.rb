module Api
  module Subcollections
    module SecurityGroups
      def security_groups_query_resource(object)
        object.respond_to?(:security_groups) ? object.security_groups : []
      end

      def security_groups_add_resource(parent, _type, _id, data)
        security_group = data["security_group"]

        begin
          message = "Adding security group #{security_group} to #{parent.name}"
          task_id = queue_object_action(parent, message, :method_name => "add_security_group", :args => [security_group])
          action_result(true, message, :task_id => task_id)
        rescue => e
          action_result(false, e.to_s)
        end
      end

      def security_groups_remove_resource(parent, _type, _id, data)
        security_group = data["security_group"]

        begin
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
