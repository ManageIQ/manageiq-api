module Api
  class PhysicalStoragesController < BaseController
    def refresh_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Refreshing", :method_name => :refresh_ems)
    end

    def create_resource(_type, _id = nil, data = {})
      ext_management_system = ExtManagementSystem.find(data['ems_id'])
      task_id = PhysicalStorage.create_physical_storage_queue(session[:userid], ext_management_system, data)
      action_result(true, "Creating Physical Storage #{data['name']} for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def edit_resource(type, id, data = {})
      raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id

      physical_storage = resource_search(id, type)

      raise BadRequestError, physical_storage.unsupported_reason(:update) unless physical_storage.supports?(:update)

      task_id = physical_storage.update_physical_storage_queue(User.current_user, data)
      action_result(true, "Updating #{physical_storage.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    # really shouldn't override, but want the word Detaching in there
    def delete_resource_action(type, id = nil, data = nil)
      api_resource(type, id, "Detaching") do |resource|
        delete_resource_main_action(type, resource, data)
      end
    end

    def delete_resource_main_action(type, physical_storage, _data = nil)
      ensure_supports(type, physical_storage, :delete)
      {:task_id => physical_storage.delete_physical_storage_queue(User.current_user)}
    end
  end
end
