module Api
  class PhysicalSwitchesController < BaseController
    include Api::Mixins::Operations
    include Subcollections::EventStreams

    def refresh_resource(type, id, _data = nil)
      perform_action(:refresh_ems, type, id)
    end

    def restart_resource(type, id, _data = nil)
      perform_action(:restart, type, id)
    end
  end
end
