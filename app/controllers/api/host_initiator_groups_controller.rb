module Api
  class HostInitiatorGroupsController < BaseController
    def refresh_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Refreshing", :method_name => :refresh_ems)
    end

    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, klass|
        {:task_id => klass.create_host_initiator_group_queue(User.current_userid, ems, data)}
      end
    end

    def delete_resource_action(type, id = nil, _data = nil)
      api_resource(type, id, "Deleting", :supports => :delete) do |host_initiator_group|
        {:task_id => host_initiator_group.delete_host_initiator_group_queue(User.current_userid)}
      end
    end

    def edit_resource(type, id, data = {})
      api_resource(type, id, "Updating", :supports => :update) do |host_initiator_group|
        {:task_id => host_initiator_group.update_host_initiator_group_queue(User.current_userid, data.deep_symbolize_keys)}
      end
    end
  end
end
