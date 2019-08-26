module Api
  class PhysicalRacksController < BaseController
    def refresh_resource(type, id, _data = nil)
      api_action(type, id) do |klass|
        physical_rack = resource_search(id, type, klass)
        api_log_info("Refreshing #{physical_rack_ident(physical_rack)}")
        refresh_physical_rack(physical_rack)
      end
    end

    private

    def refresh_physical_rack(physical_rack)
      desc = "#{physical_rack_ident(physical_rack)} refreshing"
      task_id = queue_object_action(physical_rack, desc, :method_name => "refresh_ems", :role => "ems_operations")
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def physical_rack_ident(physical_rack)
      "Physical Rack id:#{physical_rack.id} name:'#{physical_rack.name}'"
    end
  end
end
