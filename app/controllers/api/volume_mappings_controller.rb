module Api
  class VolumeMappingsController < BaseController
    def refresh_resource(type, id, _data = nil)
      raise BadRequestError, "Must specify an id for refreshing a #{type} resource" if id.blank?

      ensure_resource_exists(type, id) if single_resource?

      api_action(type, id) do |klass|
        volume_mapping = resource_search(id, type, klass)
        api_log_info("Refreshing #{volume_mapping_ident(volume_mapping)}")
        refresh_volume_mapping(volume_mapping)
      end
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

    def delete_resource(type, id, _data = nil)
      raise BadRequestError, "Deleting #{type.to_s.titleize} requires an id" if id.blank?

      ensure_resource_exists(type, id) if single_resource?

      api_action(type, id) do |klass|
        volume_mapping = resource_search(id, type, klass)
        unless volume_mapping.supports?(:delete)
          error_msg = "Failed to delete volume mapping: #{volume_mapping.unsupported_reason(:delete)}"
          raise error_msg
        end
        task_id = volume_mapping.delete_volume_mapping_queue(User.current_user)
        msg = "Deleting #{model_ident(volume_mapping, type)}"
        action_result(true, msg, :task_id => task_id)
      rescue => err
        action_result(false, err.to_s)
      end
    end

    private

    def ensure_resource_exists(type, id)
      raise NotFoundError, "#{type} with id:#{id} not found" unless collection_class(type).exists?(id)
    end

    def refresh_volume_mapping(volume_mapping)
      desc = "#{volume_mapping_ident(volume_mapping)} refreshing"
      task_id = queue_object_action(volume_mapping, desc, :method_name => "refresh_ems", :role => "ems_operations")
      action_result(true, "#{volume_mapping_ident(volume_mapping)} refreshing", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def volume_mapping_ident(volume_mapping)
      "Volume Mapping id:#{volume_mapping.id}"
    end
  end
end
