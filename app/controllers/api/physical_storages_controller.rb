module Api
  class PhysicalStoragesController < BaseController
    include Subcollections::PhysicalRacks
    include Subcollections::PhysicalChassis

    def refresh_resource(type, id, _data = nil)
      raise BadRequestError, "Must specify an id for refreshing a #{type} resource" if id.blank?

      ensure_resource_exists(type, id) if single_resource?

      api_action(type, id) do |klass|
        physical_storage = resource_search(id, type, klass)
        api_log_info("Refreshing #{physical_storage_ident(physical_storage)}")
        refresh_physical_storage(physical_storage)
      end
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
