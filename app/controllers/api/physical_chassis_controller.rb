module Api
  class PhysicalChassisController < BaseController
    include Subcollections::EventStreams

    def blink_loc_led_resource(type, id, _data)
      enqueue_action(type, id, :method_name => :blink_loc_led)
    end

    def turn_on_loc_led_resource(type, id, _data)
      enqueue_action(type, id, :method_name => :turn_on_loc_led)
    end

    def turn_off_loc_led_resource(type, id, _data)
      enqueue_action(type, id, :method_name => :turn_off_loc_led)
    end

    def refresh_resource(type, id, _data = nil)
      enqueue_action(type, id, "Refreshing", :method_name => :refresh_ems)
    end
  end
end
