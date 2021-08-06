module Api
  class CloudNetworksController < BaseController
    include Subcollections::Tags

    def delete_resource(type, resource_id, _data = {})
      raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless resource_id

      cloud_network = resource_search(resource_id, type, collection_class(type))
      task_id = cloud_network.delete_cloud_network_queue(User.current_user.userid)
      action_result(true, "Deleting #{cloud_network.name}", :task_id => task_id)
    end

    private def options_by_ems_id
      if params["ems_id"] == "nil"
        render_options(:cloud_networks, :form_schema => {:fields => []})
      else
        ems = resource_search(params["ems_id"], :ext_management_systems, ExtManagementSystem)
        klass = CloudNetwork.class_by_ems(ems)

        raise BadRequestError, "No Cloud Network support for - #{ems.class}" unless defined?(ems.class::CloudNetwork)

        raise BadRequestError, "No DDF specified for - #{klass}" unless klass.supports?(:create)

        render_options(:cloud_networks, :form_schema => klass.params_for_create(ems))
      end
    end

    private def options_by_id
      cloud_network = resource_search(params["id"], :cloud_networks, CloudNetwork)
      render_options(:cloud_networks, :form_schema => cloud_network.params_for_edit)
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
