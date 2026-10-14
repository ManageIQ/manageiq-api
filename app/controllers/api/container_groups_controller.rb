module Api
  class ContainerGroupsController < BaseController
    def check_compliance_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Check Compliance for", :method_name => "check_compliance", :supports => true)
    end

    def logs_resource(type, id, data)
      api_resource(type, id, "Fetching logs for", :supports => :logs) do |container_group|
        {:task_id => container_group.logs_queue(User.current_user.userid, data || {})}
      end
    end
  end
end
