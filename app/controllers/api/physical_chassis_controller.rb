module Api
  class PhysicalChassisController < BaseController
    include Subcollections::EventStreams
    include Api::Mixins::Operations

    def blink_loc_led_resource(type, id, _data)
      perform_action(:blink_loc_led, type, id)
    end

    def turn_on_loc_led_resource(type, id, _data)
      perform_action(:turn_on_loc_led, type, id)
    end

    def turn_off_loc_led_resource(type, id, _data)
      perform_action(:turn_off_loc_led, type, id)
    end

    def refresh_resource(type, id, _data = nil)
      perform_action(:refresh_ems, type, id)
    end
  end
end
