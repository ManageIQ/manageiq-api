module Api
  class SecurityPoliciesController < BaseController
    include Subcollections::Tags
    include Subcollections::SecurityPolicyRules

    def delete_resource_main_action(_type, security_policy, _data = {})
      {:task_id => security_policy.delete_security_policy_queue(User.current_user.userid)}
    end
  end
end
