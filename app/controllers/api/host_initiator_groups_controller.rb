module Api
  class HostInitiatorGroupsController < BaseController
    def create_resource(type, _id = nil, data = {})
      raise BadRequestError, "ems_id not defined for #{type} resource" if data['ems_id'].blank?

      ext_management_system = resource_search(data['ems_id'], :providers)

      klass = HostInitiatorGroup.class_by_ems(ext_management_system)
      raise BadRequestError, klass.unsupported_reason(:create) unless klass.supports?(:create)

      task_id = HostInitiatorGroup.create_host_initiator_group_queue(session[:userid], ext_management_system, data)
      action_result(true, "Creating Host Initiator Group #{data['name']} for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end
  end
end
