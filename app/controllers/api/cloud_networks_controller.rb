module Api
  class CloudNetworksController < BaseController
    include Subcollections::Tags

    def delete_resource_main_action(_type, cloud_network, _data = {})
      # TODO: ensure_supports(type, cloud_network, :delete)
      {:task_id => cloud_network.delete_cloud_network_queue(User.current_user.userid)}
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
