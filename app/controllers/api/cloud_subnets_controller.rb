module Api
  class CloudSubnetsController < BaseProviderController
    include Subcollections::Tags

    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, _klass|
        {:task_id => ems.create_cloud_subnet_queue(User.current_userid, data.deep_symbolize_keys)}
      end
    end

    def edit_resource(type, id, data)
      api_resource(type, id, "Updating", :supports => :update) do |cloud_subnet|
        {:task_id => cloud_subnet.update_cloud_subnet_queue(User.current_userid, data.deep_symbolize_keys)}
      end
    end

    def delete_resource_main_action(type, cloud_subnet, _data)
      ensure_supports(type, cloud_subnet, :delete)
      {:task_id => cloud_subnet.delete_cloud_subnet_queue(User.current_userid)}
    end
  end
end
