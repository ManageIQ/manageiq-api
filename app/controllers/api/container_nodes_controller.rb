module Api
  class ContainerNodesController < BaseController
    def check_compliance_resource(type, id, _data = nil)
      api_action(type, id) do |klass|
        container_node = resource_search(id, type, klass)
        api_log_info("Checking compliance of #{container_node_ident(container_node)}")
        request_compliance_check(container_node)
      end
    end

    private

    def container_node_ident(container_node)
      "ContainerNode id:#{container_node.id} name:'#{container_node.name}'"
    end

    def request_compliance_check(container_node)
      desc = "#{container_node_ident(container_node)} check compliance requested"
      raise "#{container_node_ident(container_node)} has no compliance policies assigned" if container_node.compliance_policies.blank?

      task_id = queue_object_action(container_node, desc, :method_name => "check_compliance")
      action_result(true, desc, :task_id => task_id)
    rescue StandardError => err
      action_result(false, err.to_s)
    end
  end
end
