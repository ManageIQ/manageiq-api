module Api
  class SecurityPolicyRulesController < BaseController
    include Subcollections::Tags

    def delete_resource_main_action(_type, security_policy_rule, _data = {})
      {:task_id => security_policy_rule.delete_security_policy_rule_queue(User.current_user.userid)}
    end
  end
end
