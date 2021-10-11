module Api
  class SecurityGroupsController < BaseController
    include Subcollections::Tags

    def delete_resource_main_action(_type, security_group, _data = {})
      {:task_id => security_group.delete_security_group_queue(User.current_user.userid)}
    end
  end
end
