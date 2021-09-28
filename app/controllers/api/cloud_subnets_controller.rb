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

    def create_resource(type, _id = nil, data = {})
      create_resource_task_result(type, data['ems_id'], :name => data['name']) do |ems|
        ems.create_cloud_subnet_queue(User.current_userid, data.deep_symbolize_keys) # returns task_id
      end
    end

    def edit_resource(type, id, data)
      resource_task_result(type, id, :update) do |cloud_subnet|
        cloud_subnet.update_cloud_subnet_queue(User.current_userid, data.deep_symbolize_keys) # returns task_id
      end
    end

    def delete_resource(type, id, _data = {})
      resource_task_result(type, id, :delete) do |cloud_subnet|
        cloud_subnet.delete_cloud_subnet_queue(User.current_userid) # returns task_id
      end
    end
  end
end
