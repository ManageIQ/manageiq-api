module Api
  class SecurityGroupsController < BaseController
    include Subcollections::Tags

    def delete_resource(type, resource_id, _data = {})
      raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless resource_id

      security_group = resource_search(resource_id, type, collection_class(type))
      task_id = security_group.delete_security_group_queue(User.current_user.userid)
      action_result(true, "Deleting #{security_group.name}", :task_id => task_id)
    end
  end
end
