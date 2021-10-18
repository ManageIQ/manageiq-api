module Api
  class CloudSubnetsController < BaseController
    include Subcollections::Tags

    def options
      return super unless params[:ems_id]

      ems = ExtManagementSystem.find(params[:ems_id])

      raise BadRequestError, "No CloudSubnet support for - #{ems.class}" unless defined?(ems.class::CloudSubnet)

      klass = ems.class::CloudSubnet

      raise BadRequestError, "No DDF specified for - #{klass}" unless klass.respond_to?(:params_for_create)

      render_options(:cloud_subnets, :form_schema => klass.params_for_create(ems))
    end

    def create_resource(_type, _id = nil, data = {})
      ems = ExtManagementSystem.find(data['ems_id'])
      klass = CloudSubnet.class_by_ems(ems)
      raise BadRequestError, "Cannot create cloud subnet for Provider #{ems.name}: #{klass.unsupported_reason(:create)}" unless klass.supports?(:create)

      task_id = ems.create_cloud_subnet_queue(session[:userid], data.deep_symbolize_keys)
      action_result(true, "Creating Cloud Subnet #{data['name']} for Provider: #{ems.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def edit_resource(type, id, data)
      cloud_subnet = resource_search(id, type, collection_class(:cloud_subnets))
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
