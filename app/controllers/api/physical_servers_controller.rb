module Api
  class PhysicalServersController < BaseController
    include Subcollections::EventStreams

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

    # Process apply config pattern operation for single and multi-resources
    #
    # Even the request for multi-resources isn't completed successfully, return a HTTP Status 200
    def apply_config_pattern_resource(type, id, data)
      ensure_resource_exists(:customization_scripts, data["pattern_id"])
      change_resource_state(:apply_config_pattern, type, id, [data["pattern_id"]])
    rescue => err
      raise err if single_resource?
      action_result(false, err.to_s)
    end

    def apply_config_pattern_ansible_resource(type, id, data)
      raise(BadRequestError, 'Please provide a pattern_id') unless data.key?('pattern_id')
      description = 'Applying a config pattern'
      args = [:ansible_apply_pattern, data['pattern_id'], current_user.id]
      execute_ansible_on_server(type, id, description, args)
    end

    def apply_firmware_update_ansible_resource(type, id, data)
      description = 'Applying firmware update'
      args = [:ansible_update_firmware, data['firmware_names'], current_user.id]
      execute_ansible_on_server(type, id, description, args)
    end

    private

    def execute_ansible_on_server(type, id, desc, args)
      api_action(type, id) do |klass|
        begin
          server = resource_search(id, type, klass)
          desc = "Applying firmware update"
          api_log_info(desc)
          task_id = queue_object_action(server,
                                        desc,
                                        :method_name => 'task_ansible_run',
                                        :role        => :ems_operations,
                                        :args        => args)
          action_result(true, desc, :task_id => task_id)
        rescue => err
          raise err if single_resource?
          action_result(false, err.to_s)
        end
      end
    end

    def change_resource_state(state, type, id, data = [])
      raise BadRequestError, "Must specify an id for changing a #{type} resource" unless id

      ensure_resource_exists(type, id) if single_resource?

      api_action(type, id) do |klass|
        begin
          server = resource_search(id, type, klass)
          desc = "Requested server state #{state} for #{server_ident(server)}"
          api_log_info(desc)
          task_id = queue_object_action(server, desc, :method_name => state, :role => :ems_operations, :args => data)
          action_result(true, desc, :task_id => task_id)
        rescue => err
          action_result(false, err.to_s)
        end
      end
    end

    def ensure_resource_exists(type, id)
      raise NotFoundError, "#{type} with id:#{id} not found" unless collection_class(type).exists?(id)
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
