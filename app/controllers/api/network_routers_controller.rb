module Api
  class NetworkRoutersController < BaseProviderController
    include Subcollections::Tags

    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, _klass|
        {:task_id => ems.create_network_router_queue(User.current_userid, data.deep_symbolize_keys)}
      end
    end

    def edit_resource(type, id, data)
      api_resource(type, id, "Updating", :supports => :update) do |network_router|
        {:task_id => network_router.update_network_router_queue(User.current_userid, data.deep_symbolize_keys)}
      end
    end

    def delete_resource_main_action(type, network_router, _data)
      ensure_respond_to(type, network_router, :delete, :delete_network_router_queue)
      {:task_id => network_router.delete_network_router_queue(User.current_userid)}
    end
  end
end
