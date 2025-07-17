module Api
  class ContainerVolumesController < BaseController
    def attach_resource(data = {})
      vm_id = data["vm_id"] || params[:c_id]
      raise BadRequestError, "Must specify a vm_id" if vm_id.blank?

      pvc_name    = data["pvc_name"]    || params.dig(:resource, :pvc_name)
      volume_name = data["volume_name"] || params.dig(:resource, :volume_name)

      vm = resource_search(vm_id, :vms)

      unless vm.supports?(:attach)
        raise BadRequestError, "VM does not support attach"
      end

      {:task_id => vm.raw_attach_volume(vm, pvc_name, volume_name)}
    rescue => err
      action_result(false, err.to_s)
    end

    def create_and_attach_volume_resource(data = {})
      vm_id = data["vm_id"] || params[:c_id]
      raise BadRequestError, "Must specify a vm_id" if vm_id.blank?

      volume_name = data["volume_name"] || params.dig(:resource, :volume_name)
      volume_size = data["volume_size"] || params.dig(:resource, :volume_size)

      vm = resource_search(vm_id, :vms)

      unless vm.supports?(:attach)
        raise BadRequestError, "VM does not support attach"
      end

      {:task_id => vm.create_pvc(vm, volume_name, volume_size)}
    rescue => err
      action_result(false, err.to_s)
    end

    def detach_resource(data = {})
      vm_id = data["vm_id"] || params[:c_id]
      raise BadRequestError, "Must specify a vm_id" if data["vm_id"].blank?

      volume_name = data["volume_name"] || params.dig(:resource, :volume_name)

      vm = resource_search(vm_id, :vms)
      {:task_id => vm.raw_detach_volume(vm, volume_name)}
    rescue => err
      action_result(false, err.to_s)
    end
  end
end
