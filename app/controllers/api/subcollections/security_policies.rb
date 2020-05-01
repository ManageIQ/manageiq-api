module Api
  module Subcollections
    module SecurityPolicies
      def security_policies_query_resource(object)
        object.respond_to?(:security_policies) ? object.security_policies : {}
      end

      def security_policies_create_resource(provider, _type, _resource_id, data)
        raise 'Must specify a name for the security policy' unless data[:name]

        message = "Creating security policy"
        data.deep_symbolize_keys!
        task_id = queue_object_action(provider, message, :method_name => "create_security_policy", :args => [data])
        action_result(true, message, :task_id => task_id)
      rescue => e
        action_result(false, e.to_s)
      end

      def security_policies_edit_resource(_object, type, resource_id = nil, data = {})
        raise BadRequestError, "Must specify an id for updating a #{type} resource" unless resource_id

        data.deep_symbolize_keys!
        security_policy = resource_search(resource_id, type, collection_class(type))
        task_id = security_policy.update_security_policy_queue(User.current_user.userid, data)
        action_result(true, "Updating #{security_policy.name}", :task_id => task_id)
      end

      def security_policies_delete_resource(_parent, type, resource_id, _data)
        delete_resource(type, resource_id, data)
      end
    end
  end
end
