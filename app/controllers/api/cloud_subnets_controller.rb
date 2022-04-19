module Api
  class CloudSubnetsController < BaseProviderController
    include Subcollections::Tags

    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, _klass|
        {:task_id => ems.create_cloud_subnet_queue(User.current_userid, data.deep_symbolize_keys)}
      end
    end

    def edit_resource(type, id, data)
      cloud_subnet = resource_search(id, type)
      raise BadRequestError, "Cannot update #{cloud_subnet_ident(cloud_subnet)}: #{cloud_subnet.unsupported_reason(:update)}" unless cloud_subnet.supports?(:update)

      task_id = cloud_subnet.update_cloud_subnet_queue(session[:userid], data.deep_symbolize_keys)
      action_result(true, "Updating #{cloud_subnet_ident(cloud_subnet)}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource_main_action(type, cloud_subnet, _data)
      ensure_supports(type, cloud_subnet, :delete)
      {:task_id => cloud_subnet.delete_cloud_subnet_queue(User.current_userid)}
    end

    private

    def cloud_subnet_ident(cloud_subnet)
      "Cloud Subnet id: #{cloud_subnet.id} name: '#{cloud_subnet.name}'"
    end
  end
end
