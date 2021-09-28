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
      create_resource_task_result(type, data['ems_id'], :name => data['name']) do |ems|
        VolumeMapping.create_volume_mapping_queue(User.current_userid, ems, data) # returns task_id
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
