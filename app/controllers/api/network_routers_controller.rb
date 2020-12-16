module Api
  class NetworkRoutersController < BaseController
    include Subcollections::Tags

    def edit_resource(type, id, data)
      network_router = resource_search(id, type, collection_class(:network_routers))
      raise BadRequestError, "Update for #{network_router_ident(network_router)}: #{network_router.unsupported_reason(:update)}" unless network_router.supports_update?

      task_id = network_router.update_network_router_queue(User.current_user.id, data.deep_symbolize_keys)
      action_result(true, "Updating #{network_router_ident(network_router)}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource(type, id, _data = {})
      delete_action_handler do
        network_router = resource_search(id, type, collection_class(:network_routers))
        raise "Delete not supported for #{network_router_ident(network_router)}" unless network_router.respond_to?(:delete_network_router_queue)
        task_id = network_router.delete_network_router_queue(User.current_user.id)
        action_result(true, "Deleting #{network_router_ident(network_router)}", :task_id => task_id)
      end
    end

    private

    def network_router_ident(network_router)
      "Network Router id:#{network_router.id} name: '#{network_router.name}'"
    end
  end
end
