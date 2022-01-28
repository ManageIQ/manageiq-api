module Api
  class HostInitiatorsController < BaseController
    def refresh_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Refreshing", :method_name => :refresh_ems)
    end

    def create_resource(_type, _id = nil, data = {})
      raise BadRequestError, "ems_id not defined for #{_type} resource" if data['ems_id'].blank?

      ext_management_system = resource_search(data['ems_id'], :providers)
      task_id = HostInitiator.create_host_initiator_queue(session[:userid], ext_management_system, data)
      action_result(true, "Creating Host Initiator #{data['name']} for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end
  end
end
