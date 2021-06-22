module Api
  class InstancesController < BaseController
    include Subcollections::CustomAttributes
    include Subcollections::LoadBalancers
    include Subcollections::SecurityGroups
    include Subcollections::Snapshots
    extend Api::Mixins::CentralAdmin

    DEFAULT_ROLE = 'ems_operations'.freeze

    def terminate_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for terminating a #{type} resource" unless id

      api_action(type, id) do |klass|
        instance = resource_search(id, type, klass)
        api_log_info("Terminating #{instance_ident(instance)}")
        terminate_instance(instance)
      end
    end

    def stop_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for stopping a #{type} resource" unless id

      api_action(type, id) do |klass|
        instance = resource_search(id, type, klass)
        api_log_info("Stopping #{instance_ident(instance)}")

        result = validate_instance_for_action(instance, "stop")
        result = stop_instance(instance) if result[:success]
        result
      end
    end
    central_admin :stop_resource, :stop

    def start_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for starting a #{type} resource" unless id

      api_action(type, id) do |klass|
        instance = resource_search(id, type, klass)
        api_log_info("Starting #{instance_ident(instance)}")

        result = validate_instance_for_action(instance, "start")
        result = start_instance(instance) if result[:success]
        result
      end
    end
    central_admin :start_resource, :start

    def pause_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for pausing a #{type} resource" unless id

      api_action(type, id) do |klass|
        instance = resource_search(id, type, klass)
        api_log_info("Pausing #{instance_ident(instance)}")

        result = validate_instance_for_action(instance, "pause")
        result = pause_instance(instance) if result[:success]
        result
      end
    end

    def suspend_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for suspending a #{type} resource" unless id

      api_action(type, id) do |klass|
        instance = resource_search(id, type, klass)
        api_log_info("Suspending #{instance_ident(instance)}")

        result = validate_instance_for_action(instance, "suspend")
        result = suspend_instance(instance) if result[:success]
        result
      end
    end
    central_admin :suspend_resource, :suspend

    def shelve_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for shelving a #{type} resource" unless id

      api_action(type, id) do |klass|
        instance = resource_search(id, type, klass)
        api_log_info("Shelving #{instance_ident(instance)}")

        result = validate_instance_for_action(instance, "shelve")
        result = shelve_instance(instance) if result[:success]
        result
      end
    end

    def reboot_guest_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for rebooting a #{type} resource" unless id

      api_action(type, id) do |klass|
        instance = resource_search(id, type, klass)
        api_log_info("Rebooting #{instance_ident(instance)}")

        result = validate_instance_for_action(instance, "reboot_guest")
        result = reboot_guest_instance(instance) if result[:success]
        result
      end
    end
    central_admin :reboot_guest_resource, :reboot_guest

    def reset_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for resetting a #{type} resource" unless id

      api_action(type, id) do |klass|
        instance = resource_search(id, type, klass)
        api_log_info("Resetting #{instance_ident(instance)}")

        result = validate_instance_for_action(instance, "reset")
        result = reset_instance(instance) if result[:success]
        result
      end
    end
    central_admin :reset_resource, :reset

    def check_compliance_resource(type, id, _data = nil)
      api_action(type, id) do |klass|
        instance = resource_search(id, type, klass)
        api_log_info("Checking compliance of #{instance_ident(instance)}")
        request_compliance_check(instance)
      end
    end

    def options
      return super unless @req.subcollection?
  
      # Try to look for subcollection specific options
      subcollection_options_method = "#{@req.subject}_subcollection_options"
      return super unless respond_to?(subcollection_options_method)
  
      vm = resource_search(params[:c_id], @req.collection, collection_class(@req.collection))
      render_options(@req.collection.to_sym, send(subcollection_options_method, vm))
    end

    private

    def instance_ident(instance)
      "Instance id:#{instance.id} name:'#{instance.name}'"
    end

    def terminate_instance(instance)
      desc = "#{instance_ident(instance)} terminating"
      task_id = queue_object_action(instance, desc, queue_options("vm_destroy", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def stop_instance(instance)
      desc = "#{instance_ident(instance)} stopping"
      task_id = queue_object_action(instance, desc, queue_options("stop", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def start_instance(instance)
      desc = "#{instance_ident(instance)} starting"
      task_id = queue_object_action(instance, desc, queue_options("start", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def pause_instance(instance)
      desc = "#{instance_ident(instance)} pausing"
      task_id = queue_object_action(instance, desc, queue_options("pause", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def validate_instance_for_action(instance, action)
      action_result(instance.supports?(action), instance.unsupported_reason(action.to_sym))
    end

    def suspend_instance(instance)
      desc = "#{instance_ident(instance)} suspending"
      task_id = queue_object_action(instance, desc, queue_options("suspend", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def shelve_instance(instance)
      desc = "#{instance_ident(instance)} shelving"
      task_id = queue_object_action(instance, desc, queue_options("shelve", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def reboot_guest_instance(instance)
      desc = "#{instance_ident(instance)} rebooting"
      task_id = queue_object_action(instance, desc, queue_options("reboot_guest", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def reset_instance(instance)
      desc = "#{instance_ident(instance)} resetting"
      task_id = queue_object_action(instance, desc, queue_options("reset", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def request_compliance_check(instance)
      desc = "#{instance_ident(instance)} check compliance requested"
      raise "#{instance_ident(instance)} has no compliance policies assigned" if instance.compliance_policies.blank?

      task_id = queue_object_action(instance, desc, :method_name => "check_compliance")
      action_result(true, desc, :task_id => task_id)
    rescue StandardError => err
      action_result(false, err.to_s)
    end
  end
end
