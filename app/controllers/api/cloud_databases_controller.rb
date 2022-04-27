module Api
  class CloudDatabasesController < BaseController
    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, klass|
        {:task_id => klass.create_cloud_database_queue(User.current_userid, ems, data)}
      end
    end
  end
end
