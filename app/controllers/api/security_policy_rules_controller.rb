module Api
  class SecurityPolicyRulesController < BaseController
    include Subcollections::Tags

    def delete_resource(type, resource_id, _data = {})
      raise BadRequestError, "Deleting #{type.to_s.titleize} requires an id" unless resource_id

      security_policy_rule = resource_search(resource_id, type, collection_class(type))
      task_id = security_policy_rule.delete_security_policy_rule_queue(User.current_user.userid)
      action_result(true, "Deleting #{security_policy_rule.name}", :task_id => task_id)
    end
  end
end
