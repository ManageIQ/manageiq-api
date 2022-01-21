module Api
  class HostInitiatorGroupsController < BaseController
    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, klass|
        {:task_id => klass.create_host_initiator_group_queue(User.current_userid, ems, data)}
      end
    end
  end
end
