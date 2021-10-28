module Api
  class PhysicalSwitchesController < BaseController
    include Subcollections::EventStreams

    def refresh_resource(type, id, _data = nil)
      enqueue_action(type, id, "Refreshing", :method_name => :refresh_ems)
    end

    def restart_resource(type, id, _data = nil)
      enqueue_action(type, id, "Restarting", :method_name => :restart)
    end
  end
end
