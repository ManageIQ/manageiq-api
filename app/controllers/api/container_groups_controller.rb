module Api
  class ContainerGroupsController < BaseController
    def check_compliance_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Check Compliance for", :method_name => "check_compliance", :supports => true)
    end

    def logs_resource(type, id, data)
      container_group = resource_search(id, type, ContainerGroup)
      container_name  = data && data["container"]

      {:logs => container_group.logs(container_name)}
    end
  end
end
