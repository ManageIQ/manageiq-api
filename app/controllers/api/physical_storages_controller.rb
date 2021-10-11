module Api
  class PhysicalStoragesController < BaseController
    def refresh_resource(type, id, _data = nil)
      raise BadRequestError, "Must specify an id for refreshing a #{type} resource" if id.blank?

      ensure_resource_exists(type, id) if single_resource?

      api_action(type, id) do |klass|
        physical_storage = resource_search(id, type, klass)
        api_log_info("Refreshing #{physical_storage_ident(physical_storage)}")
        refresh_physical_storage(physical_storage)
      end
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

      physical_storage = resource_search(id, type, collection_class(:physical_storages))

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

    private

    def ensure_resource_exists(type, id)
      raise NotFoundError, "#{type} with id:#{id} not found" unless collection_class(type).exists?(id)
    end

    def refresh_physical_storage(physical_storage)
      method_name = "refresh_ems"
      role = "ems_operations"

      act_refresh(physical_storage, method_name, role)
    rescue => err
      action_result(false, err.to_s)
    end

    def physical_storage_ident(physical_storage)
      "Physical Storage id:#{physical_storage.id} name:'#{physical_storage.name}'"
    end

    def act_refresh(physical_storage, method_name, role)
      desc = "#{physical_storage_ident(physical_storage)} refreshing"
      task_id = queue_object_action(physical_storage, desc, :method_name => method_name, :role => role)
      action_result(true, desc, :task_id => task_id)
    end
  end
end
