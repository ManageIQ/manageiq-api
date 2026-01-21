module Api
  class VmsController < BaseProviderController
    extend Api::Mixins::CentralAdmin
    include Api::Mixins::PolicySimulation
    include Api::Mixins::Genealogy
    include Subcollections::Accounts
    include Subcollections::Cdroms
    include Subcollections::Compliances
    include Subcollections::CustomAttributes
    include Subcollections::Disks
    include Subcollections::Metrics
    include Subcollections::MetricRollups
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::SecurityGroups
    include Subcollections::Snapshots
    include Subcollections::Software
    include Subcollections::Tags

    def start_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Starting", :method_name => "start", :supports => true)
    end
    central_admin :start_resource, :start

    def stop_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Stopping", :method_name => "stop", :supports => true)
    end
    central_admin :stop_resource, :stop

    def suspend_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Suspending", :method_name => "suspend", :supports => true)
    end
    central_admin :suspend_resource, :suspend

    def pause_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Pausing", :method_name => "pause", :supports => true)
    end

    def shelve_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Shelving", :method_name => "shelve", :supports => true)
    end

    def shelve_offload_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Shelve-Offloading", :method_name => "shelve_offload", :supports => true)
    end

    def edit_resource(type, id, data)
      edit_resource_with_genealogy(type, id, data)
    rescue => err
      raise BadRequestError, _("Cannot edit VM - %{error}") % {:error => err}
    end

    def delete_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Deleting", :method_name => "destroy")
    end

    def set_owner_resource(type, id = nil, data = nil)
      api_resource(type, id, "Setting owner of") do |vm|
        owner = data.blank? ? "" : data["owner"].strip
        raise BadRequestError, _("Must specify an owner") if owner.blank?

        user = User.lookup_by_identity(owner)
        raise BadRequestError, _("Invalid user %{owner} specified") % {:owner => owner} unless user

        vm.update!(:evm_owner => user, :miq_group => user.current_group)
        {}
      end
    end

    def scan_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Scanning", :method_name => "scan", :supports => :smartstate_analysis, :role => "smartstate")
    end

    def add_event_resource(type, id = nil, data = nil)
      raise BadRequestError, _("Must specify an id for adding an event to a %{type} resource") % {:type => type} unless id

      data ||= {}

      api_resource(type, id, "Adding Event to") do |vm|
        event_timestamp = data["event_time"].blank? ? Time.now.utc : data["event_time"].to_s.to_time(:utc)

        vm.add_ems_event(data["event_type"].to_s, data["event_message"].to_s, event_timestamp)
        {}
      end
    end

    def reset_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Resetting", :method_name => "reset", :supports => true)
    end
    central_admin :reset_resource, :reset

    def reboot_guest_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Rebooting", :method_name => "reboot_guest", :supports => true)
    end
    central_admin :reboot_guest_resource, :reboot_guest

    def rename_resource(type, id, data = {})
      new_name = data.blank? ? "" : data["new_name"].strip
      api_resource(type, id, "Renaming", :supports => :rename) do |vm|
        raise BadRequestError, _("Must specify a new_name") if new_name.blank?

        task_id = vm.rename_queue(User.current_user.userid, new_name)

        action_result(true, "Renaming #{model_ident(vm, type)} to #{new_name}", :task_id => task_id)
      end
    end
    central_admin :rename_resource, :rename

    def set_description_resource(type, id, data = {})
      new_description = data&.dig("new_description")&.strip
      api_resource(type, id, "Setting description for", :supports => :set_description) do |vm|
        raise BadRequestError, _("Must specify a new_description") if new_description.blank?

        task_id = vm.set_description_queue(User.current_userid, new_description)
        action_result(true, "Setting description for #{model_ident(vm, type)} to #{new_description}", :task_id => task_id)
      end
    end

    def shutdown_guest_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Shutting Down", :method_name => "shutdown_guest", :supports => true)
    end
    central_admin :shutdown_guest_resource, :shutdown_guest

    def refresh_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Refreshing", :method_name => :refresh_ems)
    end

    def request_console_resource(type, id = nil, data = nil)
      raise BadRequestError, _("Must specify an id for requesting a console for a %{type} resource") % {:type => type} unless id

      # NOTE:
      # for Future ?:
      #   data ||= {}
      #   protocol = data["protocol"] || "mks"
      # However, there are different entitlements for the different protocol as per miq_product_feature,
      # so we may go for different action, i.e. request_console_vnc
      # protocol = "mks"
      protocol = data["protocol"] || "vnc"

      case protocol.downcase
      when "native"
        enqueue_ems_action(type, id, "Requesting Native Console", :method_name => "native_console_connection") do |vm|
          raise _("Console protocol %{protocol} is not supported") % {:protocol => protocol} unless vm.supports?(:native_console)

          vm.validate_native_console_support
        end
      else
        args = [User.current_user.userid, MiqServer.my_server.id, protocol]
        enqueue_ems_action(type, id, "Requesting Console", :method_name => "remote_console_acquire_ticket", :args => args) do |vm|
          # NOTE: we are queuing the :remote_console_acquire_ticket and returning the task id and href.
          #
          # The remote console ticket/info can be stashed in the task's context_data by the *_acquire_ticket method
          vm.validate_remote_console_acquire_ticket(protocol)
        end
      end
    end

    def set_miq_server_resource(type, id, data)
      if data['miq_server'].empty?
        api_resource(type, id, "Removing miq_server from") do |vm|
          vm.miq_server = nil
          {}
        end
      else
        api_resource(type, id, "Setting miq_server for") do |vm|
          miq_server_id = parse_id(data['miq_server'], :servers)
          raise BadRequestError, _('Must specify a valid miq_server href or id') unless miq_server_id

          miq_server = resource_search(miq_server_id, :servers)
          vm.miq_server = miq_server
          {}
        end
      end
    end

    def request_retire_resource(type, id = nil, data = nil)
      raise BadRequestError, _("Must specify an id for retiring a %{type} resource") % {:type => type} unless id

      if data && data["date"]
        opts = {:date => data["date"]}
        opts[:warn] = data["warn"] if data["warn"]
        enqueue_action(type, id, "Retiring on #{data["date"]}", :method_name => "retire", :role => "automate", :args => [opts])
      else
        enqueue_action(type, id, "Retiring immediately", :method_name => "make_retire_request", :role => "automate", :args => [User.current_user.id])
      end
    end
    alias retire_resource request_retire_resource

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

    def associate_resource(type, id, data)
      raise BadRequestError, _("Must specify a floating_ip") if data["floating_ip"].nil?

      api_resource(type, id, "Associating resource to", :supports => :associate_floating_ip) do |vm|
        {:task_id => vm.associate_floating_ip_queue(User.current_userid, data["floating_ip"])}
      end
    end

    def disassociate_resource(type, id, data)
      raise BadRequestError, _("Must specify a floating_ip") if data["floating_ip"].nil?

      api_resource(type, id, "Disassociating resource from", :supports => :disassociate_floating_ip) do |vm|
        {:task_id => vm.disassociate_floating_ip_queue(User.current_userid, data["floating_ip"])}
      end
    end

    def resize_resource(type, id, data)
      api_resource(type, id, "Resizing Resource", :supports => :resize) do |vm|
        raise BadRequestError, _("Must specify new resize value/s") if data["resizeValues"].blank?

        {:task_id => vm.resize_queue(User.current_userid, data)}
      end
    rescue => err
      action_result(false, err.to_s)
    end
  end
end
