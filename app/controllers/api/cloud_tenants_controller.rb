module Api
  class CloudTenantsController < BaseController
    include Subcollections::SecurityGroups
    include Subcollections::Tags

    def create_resource(type, _id, data = {})
      create_resource_task_result(type, data['ems_id'], :name => data['name']) do |manager|
        data.delete('ems_id') # do for all create resources?
        # data.delete('id')
        CloudTenant.create_cloud_tenant_queue(User.current_userid, manager, data) # returns task_id
      end
    end

    def edit_resource(type, id, data = {})
      resource_task_result(type, id, :safe_delete) do |cloud_tenant|
        cloud_tenant.update_cloud_tenant_queue(User.current_userid, data) # returns task_id
      end
    end

    def delete_resource(type, id, _data = {})
      resource_task_result(type, id, :safe_delete) do |cloud_tenant|
        cloud_tenant.delete_key_pair_queue(User.current_userid, data) # returns task_id
      end
    end
  end
end
