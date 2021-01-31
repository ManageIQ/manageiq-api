module Api
  class HostInitiatorsController < BaseController
    def refresh_resource(type, id, _data = nil)
      raise BadRequestError, "Must specify an id for refreshing a #{type} resource" if id.blank?

      ensure_resource_exists(type, id) if single_resource?

      api_action(type, id) do |klass|
        host_initiator = resource_search(id, type, klass)
        api_log_info("Refreshing #{host_initiator_ident(host_initiator)}")
        refresh_host_initiator(host_initiator)
      end
    end

    def create_resource(_type, _id = nil, data = {})
      ext_management_system = ExtManagementSystem.find(data['ems_id'])
      task_id = HostInitiator.create_host_initiator_queue(session[:userid], ext_management_system, data)
      action_result(true, "Creating Host Initiator #{data['name']} for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    private

    def ensure_resource_exists(type, id)
      raise NotFoundError, "#{type} with id:#{id} not found" unless collection_class(type).exists?(id)
    end

    def refresh_host_initiator(host_initiator)
      desc = "#{host_initiator_ident(host_initiator)} refreshing"
      task_id = queue_object_action(host_initiator, desc, :method_name => "refresh_ems", :role => "ems_operations")
      action_result(true, "#{host_initiator_ident(host_initiator)} refreshing", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def host_initiator_ident(host_initiator)
      "Host Initiator id:#{host_initiator.id} name:'#{host_initiator.name}'"
    end
  end
end
