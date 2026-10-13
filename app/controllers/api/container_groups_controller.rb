module Api
  class ContainerGroupsController < BaseController
    def check_compliance_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Check Compliance for", :method_name => "check_compliance", :supports => true)
    end

    def logs_resource(type, id, data)
      api_action(type, id) do
        container_group = resource_search(id, type, ContainerGroup)
        task_id = container_group.logs_queue(User.current_user.userid, data || {})
        action_result(true, "Fetching logs for Pod #{container_group.name}", :task_id => task_id)
      end
    end
  end
end
