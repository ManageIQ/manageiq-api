module Api
  class CloudTenantsController < BaseController
    include Subcollections::SecurityGroups
    include Subcollections::Tags

    def create_resource(type, _id, data = {})
      # TODO: introduce supports for CloudTenant creation
      create_ems_resource(type, data) do |ems, klass|
        {:task_id => klass.create_cloud_tenant_queue(User.current_userid, ems, data)}
      end
    end

    def edit_resource(type, id, data = {})
      api_resource(type, id, "Updating") do |cloud_tenant|
        {:task_id => cloud_tenant.update_cloud_tenant_queue(User.current_userid, data)}
      end
    end

    def delete_resource_main_action(type, cloud_tenant, _data)
      ensure_respond_to(type, cloud_tenant, :delete, :delete_cloud_tenant_queue)
      {:task_id => cloud_tenant.delete_in_provider_queue}
    end
  end
end
