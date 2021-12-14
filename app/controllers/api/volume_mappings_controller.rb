module Api
  class VolumeMappingsController < BaseController
    def refresh_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Refreshing", :method_name => :refresh_ems)
    end

    def create_resource(_type, _id = nil, data = {})
      ext_management_system = ExtManagementSystem.find(data['ems_id'])

      klass = VolumeMapping.class_by_ems(ext_management_system)
      raise BadRequestError, klass.unsupported_reason(:create) unless klass.supports?(:create)

      task_id = VolumeMapping.create_volume_mapping_queue(session[:userid], ext_management_system, data)
      action_result(true, "Creating Volume Mapping for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource_main_action(type, volume_mapping, _data = nil)
      ensure_supports(type, volume_mapping, :delete)
      {:task_id => volume_mapping.delete_volume_mapping_queue(User.current_user)}
    end
  end
end
