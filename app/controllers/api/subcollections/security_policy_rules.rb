module Api
  module Subcollections
    module SecurityPolicyRules
      def security_policy_rules_query_resource(object)
        object.try(:security_policy_rules) || []
      end

      def security_policy_rules_create_resource(provider, _type, _resource_id, data)
        data.deep_symbolize_keys!
        raise 'Must specify a name for the security policy rule' unless data[:name]

        message = "Creating security policy rule"
        task_id = queue_object_action(provider, message, :method_name => "create_security_policy_rule", :args => [data])
        action_result(true, message, :task_id => task_id)
      rescue => e
        action_result(false, e.to_s)
      end

      def security_policy_rules_edit_resource(_object, type, resource_id = nil, data = {})
        raise BadRequestError, "Must specify an id for updating a #{type} resource" unless resource_id

        data.deep_symbolize_keys!
        security_policy_rule = resource_search(resource_id, type)
        task_id = security_policy_rule.update_security_policy_rule_queue(User.current_user.userid, data)
        action_result(true, "Updating #{security_policy_rule.name}", :task_id => task_id)
      end

      def security_policy_rules_delete_resource(_parent, type, resource_id, _data)
        delete_resource(type, resource_id, data)
      end
    end
  end
end
