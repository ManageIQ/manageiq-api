module Api
  class InstancesController < BaseController
    include Subcollections::CustomAttributes
    include Subcollections::LoadBalancers
    include Subcollections::SecurityGroups
    include Subcollections::Snapshots
    extend Api::Mixins::CentralAdmin

    def terminate_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Terminating", :method_name => "vm_destroy")
    end

    def stop_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Stopping", :method_name => "stop", :supports => true)
    end
    central_admin :stop_resource, :stop

    def start_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Starting", :method_name => "start", :supports => true)
    end
    central_admin :start_resource, :start

    def pause_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Pausing", :method_name => "pause", :supports => true)
    end

    def suspend_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Suspending", :method_name => "suspend", :supports => true)
    end
    central_admin :suspend_resource, :suspend

    def shelve_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Shelving", :method_name => "shelve", :supports => true)
    end

    def reboot_guest_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Rebooting", :method_name => "reboot_guest", :supports => true)
    end
    central_admin :reboot_guest_resource, :reboot_guest

    def reset_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Resetting", :method_name => "reset", :supports => true)
    end
    central_admin :reset_resource, :reset

    def check_compliance_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Check Compliance for", :method_name => "check_compliance", :supports => true)
    end

    def options
      return super unless @req.subcollection?
  
      # Try to look for subcollection specific options
      subcollection_options_method = "#{@req.subject}_subcollection_options"
      return super unless respond_to?(subcollection_options_method)
  
      vm = resource_search(params[:c_id], @req.collection)
      render_options(@req.collection.to_sym, send(subcollection_options_method, vm))
    end
  end
end
