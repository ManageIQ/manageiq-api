module Api
  class SecurityPoliciesController < BaseController
    include Subcollections::Tags
    include Subcollections::SecurityPolicyRules

    def delete_resource(type, id, _data = {})
      raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless id

      security_policy = resource_search(id, type, collection_class(type))
      task_id = security_policy.delete_security_policy_queue(User.current_user.userid)
      action_result(true, "Deleting #{security_policy.name}", :task_id => task_id)
    end
  end
end
