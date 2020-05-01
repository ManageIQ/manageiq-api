module Api
  module Subcollections
    module SecurityPolicies
      def security_policies_query_resource(object)
        object.respond_to?(:security_policies) ? object.security_policies : {}
      end

      def security_policies_create_resource(provider, _type, _id, data)
        begin
          data.deep_symbolize_keys!
          raise 'Must specify a name for the security policy' unless data[:name]

          message = "Creating security policy"
          task_id = queue_object_action(provider, message, :method_name => "create_security_policy", :args => [data])
          action_result(true, message, :task_id => task_id)
        rescue => e
          action_result(false, e.to_s)
        end
      end

      def security_policies_edit_resource(_object, type, id = nil, data = {})
        data.deep_symbolize_keys!

        raise BadRequestError, "Must specify an id for updating a #{type} resource" unless id
        security_policy = resource_search(id, type, collection_class(type))

        task_id = security_policy.update_security_policy_queue(User.current_user.userid, data)
        action_result(true, "Updating #{security_policy.name}", :task_id => task_id)
      end

      def security_policies_delete_resource(_parent, type, id, _data)
        raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless id
        security_policy = resource_search(id, type, collection_class(type))

        task_id = security_policy.delete_security_policy_queue(User.current_user.userid)
        action_result(true, "Deleting #{security_policy.name}", :task_id => task_id)
      end
    end
  end
end
