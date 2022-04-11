module Api
  class CloudObjectStoreContainersController < BaseController
    def create_resource(type, _ems_id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, klass|
        resource_search(data["cloud_tenant_id"], :cloud_tenants) if data["cloud_tenant_id"]
        {:task_id => klass.cloud_object_store_container_create_queue(User.current_userid, ems, data.symbolize_keys)}
      end
    end

    def options
      if (ems_id = params["ems_id"])
        render_create_resource_options(ems_id)
      else
        super
      end
    end
  end
end
