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
      raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id
      cloud_tenant = resource_search(id, type)

      task_id = cloud_tenant.update_cloud_tenant_queue(current_user.userid, data)
      action_result(true, "Updating #{cloud_tenant_ident(cloud_tenant)}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource_main_action(type, cloud_tenant, _data)
      ensure_respond_to(type, cloud_tenant, :delete, :delete_cloud_tenant_queue)
      {:task_id => cloud_tenant.delete_in_provider_queue}
    end

    private

    def cloud_tenant_ident(cloud_tenant)
      "Cloud Tenant id:#{cloud_tenant.id} name: '#{cloud_tenant.name}'"
    end
  end
end
