module Api
  class PhysicalRacksController < BaseController
    def refresh_resource(type, id, _data = nil)
      enqueue_action(type, id, "Refreshing", :method_name => :refresh_ems)
    end
  end
end
