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
  end
end
