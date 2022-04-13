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
        action = params["option_action"] || "update"
        render_update_resource_options(id, action)
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

    def attach_resource(type, id, data = {})
      api_resource(type, id, "Attaching Resource to", :supports => :attach_volume) do |cloud_volume|
        raise BadRequestError, "Must specify a vm_id" if data["vm_id"].blank?

        vm = resource_search(data["vm_id"], :vms)
        {:task_id => cloud_volume.attach_volume_queue(User.current_userid, vm.ems_ref, data["device"].presence)}
      end
    rescue => err
      action_result(false, err.to_s)
    end

    def detach_resource(type, id, data = {})
      api_resource(type, id, "Detaching Resource from", :supports => :detach_volume) do |cloud_volume|
        raise BadRequestError, "Must specify a vm_id" if data["vm_id"].blank?

        vm = resource_search(data["vm_id"], :vms)
        {:task_id => cloud_volume.detach_volume_queue(User.current_userid, vm.ems_ref)}
      end
    rescue => err
      action_result(false, err.to_s)
    end
  end
end
