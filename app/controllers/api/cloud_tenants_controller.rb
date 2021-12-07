module Api
  class CloudTenantsController < BaseController
    include Subcollections::SecurityGroups
    include Subcollections::Tags

    def create_resource(_type, _id, data = {})
      ext_management_system = resource_search(data['ems_id'], :providers)
      data.delete('ems_id')

      task_id = CloudTenant.create_cloud_tenant_queue(session[:userid], ext_management_system, data)
      action_result(true, "Creating Cloud Tenant #{data['name']} for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def edit_resource(type, id, data = {})
      raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id
      cloud_tenant = resource_search(id, type, collection_class(:cloud_tenants))

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
