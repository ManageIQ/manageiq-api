module Api
  class PhysicalServersController < BaseController
    def blink_loc_led_resource(type, id, _data)
      change_resource_state(:blink_loc_led, type, id)
    end

    def turn_on_loc_led_resource(type, id, _data)
      change_resource_state(:turn_on_loc_led, type, id)
    end

    def turn_off_loc_led_resource(type, id, _data)
      change_resource_state(:turn_off_loc_led, type, id)
    end

    def power_on_resource(type, id, _data)
      change_resource_state(:power_on, type, id)
    end

    def power_off_resource(type, id, _data)
      change_resource_state(:power_off, type, id)
    end

    def power_off_now_resource(type, id, _data)
      change_resource_state(:power_off_now, type, id)
    end

    def restart_resource(type, id, _data)
      change_resource_state(:restart, type, id)
    end

    def restart_now_resource(type, id, _data)
      change_resource_state(:restart_now, type, id)
    end

    def restart_to_sys_setup_resource(type, id, _data)
      change_resource_state(:restart_to_sys_setup, type, id)
    end

    def restart_mgmt_controller_resource(type, id, _data)
      change_resource_state(:restart_mgmt_controller, type, id)
    end

    def refresh_resource(type, id, _data = nil)
      raise BadRequestError, "Must specify an id for refreshing a #{type} resource" unless id

      ensure_resource_exists(type, id) if single_resource?

      api_action(type, id) do |klass|
        physical_server = resource_search(id, type, klass)
        api_log_info("Refreshing #{physical_server_ident(physical_server)}")
        refresh_physical_server(physical_server)
      end
    end

    def apply_config_pattern_resource(type, id, data)
      change_resource_state(:apply_config_pattern, type, id, data)
    end

    private

    def change_resource_state(state, type, id, data = {})
      validate_resource(state, type, id, data)
      api_action(type, id) do |klass|
        begin
          server = resource_search(id, type, klass)
          ensure_customization_script_exists(data["pattern_id"]) if apply_config_action(state)
          desc = "Requested server state #{state} for #{server_ident(server)}"
          api_log_info(desc)
          task_id = queue_object_action(server, desc, :method_name => state, :role => :ems_operations)
          action_result(true, desc, :task_id => task_id)
        rescue StandardError => err
          action_result(false, err.to_s)
        end
      end
    end

    def validate_resource(state, type, id, data = {})
      raise BadRequestError, "Must specify an id for changing a #{type} resource" unless id
      if single_resource?
        ensure_resource_exists(type, id)
        # Verify the configuration pattern resource if the operation is apply_config_pattern
        ensure_customization_script_exists(data["pattern_id"]) if apply_config_action(state)
      end
    end

    def apply_config_action(state)
      state == :apply_config_pattern
    end

    def ensure_customization_script_exists(id)
      ensure_resource_exists(:customization_scripts, id)
    rescue NotFoundError
      raise NotFoundError, "Customization script not found"
    end

    def ensure_resource_exists(type, id)
      raise NotFoundError unless collection_class(type).exists?(id)
    end

    def server_ident(server)
      "Server instance: #{server.id} name:'#{server.name}'"
    end

    def refresh_physical_server(physical_server)
      desc = "#{physical_server_ident(physical_server)} refreshing"
      task_id = queue_object_action(physical_server, desc, :method_name => "refresh_ems", :role => "ems_operations")
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def physical_server_ident(physical_server)
      "Physical Server id:#{physical_server.id} name:'#{physical_server.name}'"
    end
  end
end
