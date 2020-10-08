module Api
  class CloudVolumesController < BaseController
    include Subcollections::Tags

    def delete_resource(type, id, _data = {})
      delete_action_handler do
        cloud_volume = resource_search(id, type, collection_class(:cloud_volumes))
        task_id = cloud_volume.delete_volume_queue(User.current_user)
        action_result(true, "Deleting Cloud Volume #{cloud_volume.name}", :task_id => task_id)
      end
    end

    def options
      return super unless params[:ems_id]

      ems = ExtManagementSystem.find(params[:ems_id])

      raise BadRequestError, "No CloudVolume support for - #{klass}" unless defined?(ems.class::CloudVolume)

      klass = ems.class::CloudVolume

      raise BadRequestError, "No DDF specified for - #{klass}" unless klass.respond_to?(:params_for_create)

      render_options(:cloud_volumes, :form_schema => klass.params_for_create(ems))
    end
  end
end
