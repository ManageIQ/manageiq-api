module Api
  class SecurityGroupsController < BaseController
    include Subcollections::Tags

    def delete_resource(type, id, _data = {})
      raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless id
      security_group = resource_search(id, type, collection_class(type))

      if 0 < security_group.total_security_policy_rules_as_source or
        0 < security_group.total_security_policy_rules_as_destination
        raise BadRequestError, "This security group cannot be deleted as it is still in use."
      end

      task_id = security_group.delete_security_group_queue(User.current_user.userid)
      action_result(true, "Deleting #{security_group.name}", :task_id => task_id)
    end
  end
end
