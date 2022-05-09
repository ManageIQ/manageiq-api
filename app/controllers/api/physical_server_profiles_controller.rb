module Api
  class PhysicalServerProfilesController < BaseController
    include Subcollections::EventStreams

    def assign_server_resource(type, id, data)
      # Make sure the requested server exists
      resource_search(data["server_id"], :physical_servers)
      enqueue_ems_action(type, id, :method_name => :assign_server, :args => [data["server_id"]])
    end

    def deploy_server_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :deploy_server)
    end

    def unassign_server_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :unassign_server)
    end
  end
end
