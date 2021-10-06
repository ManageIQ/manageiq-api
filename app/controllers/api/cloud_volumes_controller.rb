module Api
  class CloudVolumesController < BaseController
    include Subcollections::Tags

    def create_resource(_type, _id = nil, data = {})
      ext_management_system = ExtManagementSystem.find(data['ems_id'])

      klass = CloudVolume.class_by_ems(ext_management_system)

      raise BadRequestError, ext_management_system.unsupported_reason(:cloud_volume_create) unless ext_management_system.supports?(:cloud_volume_create)

      task_id = klass.create_volume_queue(session[:userid], ext_management_system, data)
      action_result(true, "Creating Cloud Volume #{data['name']} for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def edit_resource(type, id, data = {})
      raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id

      cloud_volume = resource_search(id, type, collection_class(:cloud_volumes))

      raise BadRequestError, cloud_volume.unsupported_reason(:update) unless cloud_volume.supports?(:update)

      task_id = cloud_volume.update_volume_queue(User.current_user, data)
      action_result(true, "Updating #{cloud_volume.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def safe_delete_resource(type, id, _data = {})
      delete_action_handler do
        cloud_volume = resource_search(id, type, collection_class(:cloud_volumes))

        ensure_supports(type, cloud_volume, :safe_delete)

        task_id = cloud_volume.safe_delete_volume_queue(User.current_user)
        action_result(true, "Deleting Cloud Volume #{cloud_volume.name}", :task_id => task_id)
      end
    end

    def delete_resource(type, id, _data = {})
      delete_action_handler do
        cloud_volume = resource_search(id, type, collection_class(:cloud_volumes))
        task_id = cloud_volume.delete_volume_queue(User.current_user)
        action_result(true, "Deleting Cloud Volume #{cloud_volume.name}", :task_id => task_id)
      end
    end

    def options
      if params[:id]
        cloud_volume = resource_search(params[:id], :cloud_volumes, CloudVolume)
        render_options(:cloud_volumes, :form_schema => cloud_volume.params_for_update)
      elsif params[:ems_id]
        ems = resource_search(params[:ems_id], :ext_management_systems, ExtManagementSystem)
        raise BadRequestError, "No CloudVolume support for - #{ems.class}" unless defined?(ems.class::CloudVolume)

        klass = ems.class::CloudVolume
        raise BadRequestError, klass.unsupported_reason(:create) unless klass.supports?(:create)

        render_options(:cloud_volumes, :form_schema => klass.params_for_create(ems))
      else
        super
      end
    end
  end
end
