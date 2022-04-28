module Api
  class CloudDatabasesController < BaseController
    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, klass|
        {:task_id => klass.create_cloud_database_queue(User.current_userid, ems, data)}
      end
    end

    def edit_resource(type, id, data)
      api_resource(type, id, "Updating", :supports => :update) do |cloud_database|
        {:task_id => cloud_database.update_cloud_database_queue(User.current_userid, data.deep_symbolize_keys)}
      end
    end

    def delete_resource_main_action(type, cloud_database, _data)
      ensure_supports(type, cloud_database, :delete)
      {:task_id => cloud_database.delete_cloud_database_queue(User.current_userid)}
    end
  end
end
