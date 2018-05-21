module Api
  class PhysicalChassisController < BaseController
    def refresh_resource(type, id, _data = nil)
      raise BadRequestError, "Must specify an id for refreshing a #{type} resource" if id.blank?

      ensure_resource_exists(type, id) if single_resource?

      api_action(type, id) do |klass|
        physical_chassis = resource_search(id, type, klass)
        api_log_info("Refreshing #{physical_chassis_ident(physical_chassis)}")
        refresh_physical_chassis(physical_chassis)
      end
    end

    private

    def ensure_resource_exists(type, id)
      raise NotFoundError, "#{type} with id:#{id} not found" unless collection_class(type).exists?(id)
    end

    def refresh_physical_chassis(physical_chassis)
      method_name = "refresh_ems"
      role = "ems_operations"

      act_refresh(physical_chassis, method_name, role)
    rescue => err
      action_result(false, err.to_s)
    end

    def physical_chassis_ident(physical_chassis)
      "Physical Chassis id:#{physical_chassis.id} name:'#{physical_chassis.name}'"
    end

    def act_refresh(physical_chassis, method_name, role)
      desc = "#{physical_chassis_ident(physical_chassis)} refreshing"
      task_id = queue_object_action(physical_chassis, desc, :method_name => method_name, :role => role)
      action_result(true, desc, :task_id => task_id)
    end
  end
end
