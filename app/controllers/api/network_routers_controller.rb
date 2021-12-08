module Api
  class NetworkRoutersController < BaseController
    include Subcollections::Tags

    def create_resource(_type, _id = nil, data = {})
      ems = ExtManagementSystem.find(data['ems_id'])
      klass = NetworkRouter.class_by_ems(ems)
      raise BadRequestError, "Create network router for Provider #{ems.name}: #{klass.unsupported_reason(:create)}" unless klass.supports?(:create)

      task_id = ems.create_network_router_queue(User.current_userid, data.deep_symbolize_keys)
      action_result(true, "Creating Network Router #{data['name']} for Provider: #{ems.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def edit_resource(type, id, data)
      network_router = resource_search(id, type)
      raise BadRequestError, "Update for #{network_router_ident(network_router)}: #{network_router.unsupported_reason(:update)}" unless network_router.supports?(:update)

      task_id = network_router.update_network_router_queue(User.current_userid, data.deep_symbolize_keys)
      action_result(true, "Updating #{network_router_ident(network_router)}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource_main_action(type, network_router, _data)
      ensure_respond_to(type, network_router, :delete, :delete_network_router_queue)
      {:task_id => network_router.delete_network_router_queue(User.current_userid)}
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

    private

    def network_router_ident(network_router)
      "Network Router id:#{network_router.id} name: '#{network_router.name}'"
    end
  end
end
