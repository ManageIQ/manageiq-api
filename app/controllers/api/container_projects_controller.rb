module Api
  class ContainerProjectsController < BaseController
    include Subcollections::Tags
    include Subcollections::CustomAttributes

    def create_resource(type, _id, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, klass|
        {:task_id => klass.create_container_project_queue(User.current_userid, ems, data)}
      end
    end

    def edit_resource(type, id, data = {})
      api_resource(type, id, "Updating", :supports => :update) do |container_project|
        {:task_id => container_project.update_container_project_queue(User.current_userid, data)}
      end
    end

    def delete_resource_action(type, id = nil, _data = nil)
      api_resource(type, id, "Deleting", :supports => :delete) do |container_project|
        {:task_id => container_project.delete_container_project_queue(User.current_userid)}
      end
    end
  end
end
