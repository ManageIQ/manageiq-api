module Api
  class SecurityGroupsController < BaseController
    include Subcollections::Tags

    def delete_resource_main_action(_type, security_group, _data = {})
      {:task_id => security_group.delete_security_group_queue(User.current_user.userid)}
    end

    def options
      if (id = params["id"])
        render_update_resource_options(id)
      elsif (ems_id = params["ems_id"])
        render_create_resource_options(ems_id)
      else
        super
      end
    end
  end
end
