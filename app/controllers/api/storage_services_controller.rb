module Api
  class StorageServicesController < BaseController
    def refresh_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Refreshing", :method_name => :refresh_ems)
    end

    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, klass|
        {:task_id => klass.create_storage_service_queue(User.current_userid, ems, data)}
      end
    end

    def delete_resource_action(type, id = nil, _data = nil)
      api_resource(type, id, "Deleting", :supports => :delete) do |storage_service|
        {:task_id => storage_service.delete_storage_service_queue(User.current_userid)}
      end
    end
  end
end
