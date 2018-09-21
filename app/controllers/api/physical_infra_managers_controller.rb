module Api
  class PhysicalInfraManagersController < BaseController
    def ansible_resource(type, id, data)
      unless data.key?('playbook_name') || data.key?('role_name')
        raise(BadRequestError, 'Please provide either a playbook_name or a role_name')
      end

      api_action(type, id) do |klass|
        begin
          provider = resource_search(id, type, klass)
          desc = "Running playbook"
          api_log_info(desc)
          task_id = queue_object_action(provider, desc, :method_name => 'run_ansible', :role => :ems_operations, :args => data)
          action_result(true, desc, :task_id => task_id)
        rescue => err
          raise err if single_resource?
          action_result(false, err.to_s)
        end
      end
    end
  end
end
