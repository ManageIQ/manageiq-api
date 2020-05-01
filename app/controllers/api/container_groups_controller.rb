module Api
  class ContainerGroupsController < BaseController
    def check_compliance_resource(type, id, _data = nil)
      api_action(type, id) do |klass|
        container_group = resource_search(id, type, klass)
        api_log_info("Checking compliance of #{container_group_ident(container_group)}")
        request_compliance_check(container_group)
      end
    end

    private

    def container_group_ident(container_group)
      "ContainerGroup id:#{container_group.id} name:'#{container_group.name}'"
    end

    def request_compliance_check(container_group)
      desc = "#{container_group_ident(container_group)} check compliance requested"
      raise "#{container_group_ident(container_group)} has no compliance policies assigned" if container_group.compliance_policies.blank?

      task_id = queue_object_action(container_group, desc, :method_name => "check_compliance")
      action_result(true, desc, :task_id => task_id)
    rescue StandardError => err
      action_result(false, err.to_s)
    end
  end
end
