module Api
  class CloudNetworksController < BaseController
    include Subcollections::Tags

    def delete_resource_main_action(_type, cloud_network, _data = {})
      # TODO: ensure_supports(type, cloud_network, :delete)
      {:task_id => cloud_network.delete_cloud_network_queue(User.current_user.userid)}
    end

    private def options_by_ems_id
      ems = resource_search(params["ems_id"], :ext_management_systems, ExtManagementSystem)
      klass = CloudNetwork.class_by_ems(ems)

      raise BadRequestError, "No Cloud Network support for - #{ems.class}" unless defined?(ems.class::CloudNetwork)

      raise BadRequestError, "No DDF specified for - #{klass}" unless klass.supports?(:create)

      render_options(:cloud_networks, :form_schema => klass.params_for_create(ems))
    end

    private def options_by_id
      cloud_network = resource_search(params["id"], :cloud_networks, CloudNetwork)
      render_options(:cloud_networks, :form_schema => cloud_network.params_for_update)
    end

    def options
      if params.key?("ems_id")
        options_by_ems_id
      elsif params.key?("id")
        options_by_id
      else
        super
      end
    end
  end
end
