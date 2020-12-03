module Api
  class PhysicalStorageConsumersController < BaseController
    def refresh_resource(type, id, _data = nil)
      raise BadRequestError, "Must specify an id for refreshing a #{type} resource" if id.blank?

      ensure_resource_exists(type, id) if single_resource?

      api_action(type, id) do |klass|
        physical_storage_consumer = resource_search(id, type, klass)
        api_log_info("Refreshing #{physical_storage_consumer_ident(physical_storage_consumer)}")
        refresh_physical_storage_consumer(physical_storage_consumer)
      end
    end

    def create_resource(_type, _id = nil, data = {})
      ext_management_system = ExtManagementSystem.find(data['ems_id'])
      task_id = PhysicalStorageConsumer.create_physical_storage_consumer_queue(session[:userid], ext_management_system, data)
      action_result(true, "Creating Physical Storage Consumer #{data['name']} for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    private

    def ensure_resource_exists(type, id)
      raise NotFoundError, "#{type} with id:#{id} not found" unless collection_class(type).exists?(id)
    end

    def refresh_physical_storage_consumer(physical_storage_consumer)
      method_name = "refresh_ems"
      role = "ems_operations"

      act_refresh(physical_storage_consumer, method_name, role)
    rescue => err
      action_result(false, err.to_s)
    end

    def physical_storage_consumer_ident(physical_storage_consumer)
      "Physical Storage Consumer id:#{physical_storage_consumer.id} name:'#{physical_storage_consumer.name}'"
    end

    def act_refresh(physical_storage_consumer, method_name, role)
      desc = "#{physical_storage_consumer_ident(physical_storage_consumer)} refreshing"
      task_id = queue_object_action(physical_storage_consumer, desc, :method_name => method_name, :role => role)
      action_result(true, desc, :task_id => task_id)
    end
  end
end
