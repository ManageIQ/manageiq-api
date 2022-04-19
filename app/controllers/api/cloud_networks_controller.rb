module Api
  class CloudNetworksController < BaseProviderController
    include Subcollections::Tags

    def delete_resource_main_action(_type, cloud_network, _data = {})
      # TODO: ensure_supports(type, cloud_network, :delete)
      {:task_id => cloud_network.delete_cloud_network_queue(User.current_user.userid)}
    end
  end
end
