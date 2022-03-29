module Api
  class CloudVolumesController < BaseController
    include Subcollections::Tags

    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, klass|
        {:task_id => klass.create_volume_queue(User.current_userid, ems, data)}
      end
    end

    def edit_resource(type, id, data = {})
      raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id

      cloud_volume = resource_search(id, type)

      raise BadRequestError, cloud_volume.unsupported_reason(:update) unless cloud_volume.supports?(:update)

      task_id = cloud_volume.update_volume_queue(User.current_user, data)
      action_result(true, "Updating #{cloud_volume.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def safe_delete_resource(type, id, _data = {})
      api_resource(type, id, "Deleting", :supports => :safe_delete) do |cloud_volume|
        {:task_id => cloud_volume.safe_delete_volume_queue(User.current_userid)}
      end
    end

    def delete_resource_main_action(_type, cloud_volume, _data)
      # TODO: ensure_supports(type, cloud_volume, :delete)
      {:task_id => cloud_volume.delete_volume_queue(User.current_userid)}
    end

    def options
      if (id = params["id"])
        render_update_resource_options(id)
      elsif (ems_id = params["ems_id"])
        render_create_resource_options(ems_id)
      else
        super
      end
    end

    def create_backup_resource(type, id, data)
      api_resource(type, id, "Creating backup", :supports => :backup_create) do |cloud_volume|
        {:task_id => cloud_volume.backup_create_queue(User.current_userid, data)}
      end
    end

    def restore_backup_resource(type, id, data)
      api_resource(type, id, "Restoring backup for", :supports => :backup_restore) do |cloud_volume|
        {:task_id => cloud_volume.backup_restore_queue(User.current_userid, data.symbolize_keys)}
      end
    end
  end
end
