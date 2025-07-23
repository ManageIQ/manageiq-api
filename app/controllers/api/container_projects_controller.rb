module Api
  class ContainerProjectsController < BaseController
    include Subcollections::Tags
    include Subcollections::CustomAttributes

    def create_resource(type, _id, data = {})
      create_ems_resource(type, data) do |ems, klass|
        {:task_id => klass.create_container_project_queue(User.current_userid, ems, data)}
      end
    end

    def edit_resource(type, id, data = {})
      api_resource(type, id, "Updating") do |container_project|
        {:task_id => container_project.update_container_project_queue(User.current_userid, data)}
      end
    end

    def delete_resource_main_action(type, container_project, _data)
      ensure_respond_to(type, container_project, :delete, :delete_container_project_queue)
      {:task_id => container_project.delete_container_project_queue(User.current_userid)}
    end
  end
end
