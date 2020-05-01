module Api
  class SecurityGroupsController < BaseController
    include Subcollections::Tags

    def delete_resource(type, id, _data = {})
      raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless id

      security_group = resource_search(id, type, collection_class(type))
      task_id = security_group.delete_security_group_queue(User.current_user.userid)
      action_result(true, "Deleting #{security_group.name}", :task_id => task_id)
    end
  end
end
