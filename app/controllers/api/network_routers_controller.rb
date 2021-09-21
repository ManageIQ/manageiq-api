module Api
  class NetworkRoutersController < BaseController
    include Subcollections::Tags

    def create_resource(type, _id = nil, data = {})
      assert_id_not_specified(data, type)
      create_resource_task_result(type, data['ems_id'], :name => data['name']) do |ems|
        ems.create_network_router_queue(User.current_userid, data.deep_symbolize_keys) # returns task_id
      end
    end

    def edit_resource(type, id, data)
      resource_task_result(type, id, :update) do |network_router|
        network_router.update_network_router_queue(User.current_userid, data.deep_symbolize_keys) # returns task_id
      end
    end

    def delete_resource(type, id, _data = {})
      resource_task_result(type, id, :delete) do |network_router|
        network_router.delete_network_router_queue(User.current_userid) # returns task_id
      end
    end
  end
end
