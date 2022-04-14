module Api
  class PhysicalServerProfilesController < BaseController
    include Subcollections::EventStreams

    def assign_server_resource(type, id, data)
      enqueue_ems_action(type, id, :method_name => :assign_server, :args => [data["server_id"]]) do
        ensure_resource_exists(:physical_servers, data["server_id"])
      end
    end

    def deploy_server_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :deploy_server)
    end

    def unassign_server_resource(type, id, _data)
      enqueue_ems_action(type, id, :method_name => :unassign_server)
    end

    private

    def ensure_resource_exists(type, id)
      raise NotFoundError, "#{type} with id:#{id} not found" unless collection_class(type).exists?(id)
    end
  end
end
