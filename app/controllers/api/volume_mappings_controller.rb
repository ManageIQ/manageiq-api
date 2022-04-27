module Api
  class VolumeMappingsController < BaseProviderController
    def refresh_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Refreshing", :method_name => :refresh_ems)
    end

    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, klass|
        {:task_id => klass.create_volume_mapping_queue(User.current_user, ems, data)}
      end
    end

    def delete_resource_main_action(type, volume_mapping, _data = nil)
      ensure_supports(type, volume_mapping, :delete)
      {:task_id => volume_mapping.delete_volume_mapping_queue(User.current_user)}
    end
  end
end
