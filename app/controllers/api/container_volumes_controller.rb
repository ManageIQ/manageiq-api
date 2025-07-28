module Api
  class ContainerVolumesController < BaseController
    def attach_resource(type, id, data = {})
      api_resource(type, id, "Attaching Resource to") do |container_volume|
        vm_id = data["vm_id"] || params[:c_id]
        raise BadRequestError, "Must specify a vm_id" if vm_id.blank?

        pvc_name    = data["pvc_name"]    || params.dig(:resource, :pvc_name)
        volume_name = data["volume_name"] || params.dig(:resource, :volume_name)

        vm = resource_search(vm_id, :vms)

        unless vm.supports?(:attach)
          raise BadRequestError, "VM does not support attach"
        end

        {:task_id => container_volume.attach_volume_queue(User.current_userid, vm, pvc_name, volume_name)}
      end
    rescue => err
      action_result(false, err.to_s)
    end

    def create_and_attach_volume_resource(type, id, data = {})
      api_resource(type, id, "Attaching Resource to") do |container_volume|
        vm_id = data["vm_id"] || params[:c_id]
        raise BadRequestError, "Must specify a vm_id" if vm_id.blank?

        volume_name = data["volume_name"] || params.dig(:resource, :volume_name)
        volume_size = data["volume_size"] || params.dig(:resource, :volume_size)

        vm = resource_search(vm_id, :vms)

        unless vm.supports?(:attach)
          raise BadRequestError, "VM does not support attach"
        end

        {:task_id => container_volume.create_pvc_queue(User.current_userid, vm, volume_name, volume_size)}
      end
    rescue => err
      action_result(false, err.to_s)
    end

    def detach_resource(type, id, data = {})
      api_resource(type, id, "Detaching Resource to") do |container_volume|
        vm_id = data["vm_id"] || params[:c_id]
        raise BadRequestError, "Must specify a vm_id" if data["vm_id"].blank?

        volume_name = data["volume_name"] || params.dig(:resource, :volume_name)

        vm = resource_search(vm_id, :vms)
        {:task_id => container_volume.detach_volume_queue(User.current_userid, vm, volume_name)}
      end
    rescue => err
      action_result(false, err.to_s)
    end
  end
end
