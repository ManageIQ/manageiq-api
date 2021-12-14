module Api
  class PhysicalServersController < BaseController
    include Subcollections::EventStreams
    include Subcollections::FirmwareBinaries

    def blink_loc_led_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :blink_loc_led)
    end

    def turn_on_loc_led_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :turn_on_loc_led)
    end

    def turn_off_loc_led_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :turn_off_loc_led)
    end

    def power_on_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :power_on)
    end

    def power_off_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :power_off)
    end

    def power_off_now_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :power_off_now)
    end

    def restart_resource(type, id, _data)
      enqueue_ems_action(type, id, "Restarting", :method_name => :restart)
    end

    def restart_now_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :restart_now)
    end

    def restart_to_sys_setup_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :restart_to_sys_setup)
    end

    def restart_mgmt_controller_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :restart_mgmt_controller)
    end

    def refresh_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Refreshing", :method_name => :refresh_ems)
    end

    def apply_config_pattern_resource(type, id, data)
      enqueue_ems_action(type, id, :method_name => :apply_config_pattern, :args => [data["pattern_id"]]) do
        ensure_resource_exists(:customization_scripts, data["pattern_id"])
      end
    end

    private

    def ensure_resource_exists(type, id)
      raise NotFoundError, "#{type} with id:#{id} not found" unless collection_class(type).exists?(id)
    end
  end
end
