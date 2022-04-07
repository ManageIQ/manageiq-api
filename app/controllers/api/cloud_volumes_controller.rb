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
        p "========================= mels id was called"
        render_update_resource_options(id)
      elsif (ems_id = params["ems_id"])
        p "========================= mels ems_id"
        render_create_resource_options(ems_id)
        ## we can have a check for another param to see how it is maybe? if ems_id then if is also attach
      elsif (ems_id_attach = params["ems_id_attach"])
        p "========================= mels ems_id_attach"
        render_attach_resource_options_mels(ems_id_attach) ## this figures out the provider on its own
      else
        super
      end
    end

    def render_attach_resource_options_mels(ems_id)
      p "-------------------------- mels attach options "
      type = @req.collection.to_sym
      base_klass = collection_class(type)

      ems = resource_search(ems_id, :providers)
      klass = ems.class_by_ems(base_klass.name)
      raise BadRequestError, "No #{type.to_s.titleize} support for - #{ems.name}" unless klass
      raise BadRequestError, klass.unsupported_reason(:create) unless klass.supports?(:create)

      p "content"
      p klass
      p type
      p ems
      p "---------------------- mels render options"
      render_options(type, :form_schema => params_for_attach(ems)) ## resource or class
    end

    # def render_update_resource_options_mels(id)
    #   p "-------------------------- mels update attach options "
    #   type = @req.collection.to_sym
    #   resource = resource_search(id, type)
    #   raise BadRequestError, resource.unsupported_reason(:update) unless resource.supports?(:update)

    #   p "---------------------- mels render options"
    #   render_options(type, :form_schema => resource.params_for_attach)
    # end

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
