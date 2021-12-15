module Api
  class VmsController < BaseController
    extend Api::Mixins::CentralAdmin
    include Api::Mixins::PolicySimulation
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

    RELATIONSHIP_COLLECTIONS = %w[vms templates].freeze
    VALID_EDIT_ATTRS = %w[description name child_resources parent_resource].freeze

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
      attrs = validate_edit_data(data)
      parent, children = build_parent_children(data)
      resource_search(id, type).tap do |vm|
        vm.replace_children(children)
        vm.set_parent(parent)
        vm.update!(attrs)
      end
    rescue => err
      raise BadRequestError, "Cannot edit VM - #{err}"
    end

    def delete_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Deleting", :method_name => "destroy")
    end

    def set_owner_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for setting the owner of a #{type} resource" unless id

      owner = data.blank? ? "" : data["owner"].strip
      raise BadRequestError, "Must specify an owner" if owner.blank?

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Setting owner of #{vm_ident(vm)}")

        set_owner_vm(vm, owner)
      end
    end

    def add_lifecycle_event_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for adding a Lifecycle Event to a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Adding Lifecycle Event to #{vm_ident(vm)}")

        add_lifecycle_event_vm(vm, lifecycle_event_from_data(data))
      end
    end

    def scan_resource(type, id = nil, _data = nil)
      enqueue_ems_action(type, id, "Scanning", :method_name => "scan", :supports => :smartstate_analysis, :role => "smartstate")
    end

    def add_event_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for adding an event to a #{type} resource" unless id

      data ||= {}

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Adding Event to #{vm_ident(vm)}")

        vm_event(vm, data["event_type"].to_s, data["event_message"].to_s, data["event_time"].to_s)
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
      raise BadRequestError, "Must specify an id for renaming a #{type} resource" unless id

      new_name = data.blank? ? "" : data["new_name"].strip
      raise BadRequestError, "Must specify a new_name" if new_name.blank?

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Renaming #{vm_ident(vm)} to #{new_name}")

        result = validate_vm_for_action(vm, "rename")
        result = rename_vm(vm, new_name) if result[:success]
        result
      end
    end
    central_admin :rename_resource, :rename

    def set_description_resource(type, id, data = {})
      raise BadRequestError, "Must specify an id for renaming a #{type} resource" unless id

      new_description = data&.dig("new_description")&.strip
      raise BadRequestError, "Must specify a new_description" if new_description.blank?

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Setting description on #{vm_ident(vm)} to #{new_description}")

        result = validate_vm_for_action(vm, "set_description")
        result = set_description_vm(vm, new_description) if result[:success]
        result
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
      raise BadRequestError, "Must specify an id for requesting a console for a #{type} resource" unless id

      # NOTE:
      # for Future ?:
      #   data ||= {}
      #   protocol = data["protocol"] || "mks"
      # However, there are different entitlements for the different protocol as per miq_product_feature,
      # so we may go for different action, i.e. request_console_vnc
      # protocol = "mks"
      protocol = data["protocol"] || "vnc"

      args = [User.current_user.userid, MiqServer.my_server.id, protocol]
      enqueue_ems_action(type, id, "Requesting Console", :method_name => "remote_console_acquire_ticket", :args => args) do |vm|
        # NOTE: we are queuing the :remote_console_acquire_ticket and returning the task id and href.
        #
        # The remote console ticket/info can be stashed in the task's context_data by the *_acquire_ticket method
        vm.validate_remote_console_acquire_ticket(protocol)
      end
    end

    def set_miq_server_resource(type, id, data)
      vm = resource_search(id, type)

      miq_server = if data['miq_server'].empty?
                     nil
                   else
                     miq_server_id = parse_id(data['miq_server'], :servers)
                     raise 'Must specify a valid miq_server href or id' unless miq_server_id
                     resource_search(miq_server_id, :servers)
                   end

      vm.miq_server = miq_server
      action_result(true, "#{miq_server_message(miq_server)} for #{vm_ident(vm)}")
    rescue => err
      action_result(false, "Failed to set miq_server - #{err}")
    end

    def request_retire_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for retiring a #{type} resource" unless id

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

    private

    def miq_server_message(miq_server)
      miq_server ? "Set miq_server id:#{miq_server.id}" : "Removed miq_server"
    end

    def validate_edit_data(data)
      invalid_keys = data.keys - VALID_EDIT_ATTRS - valid_custom_attrs
      raise BadRequestError, "Cannot edit values #{invalid_keys.join(', ')}" if invalid_keys.present?
      data.except('parent_resource', 'child_resources')
    end

    def build_parent_children(data)
      children = if data.key?('child_resources')
                   data['child_resources'].collect do |child|
                     fetch_relationship(child['href'])
                   end
                 end

      parent = if data.key?('parent_resource')
                 fetch_relationship(data['parent_resource']['href'])
               end

      [parent, Array(children)]
    end

    def fetch_relationship(href)
      href = Href.new(href)
      raise "Invalid relationship type #{href.subject}" unless RELATIONSHIP_COLLECTIONS.include?(href.subject)
      resource_search(href.subject_id, href.subject)
    end

    def valid_custom_attrs
      Vm.virtual_attribute_names.select { |name| name =~ /custom_\d/ }
    end

    def vm_ident(vm)
      "VM id:#{vm.id} name:'#{vm.name}'"
    end

    def validate_vm_for_action(vm, action)
      action_result(vm.supports?(action), vm.unsupported_reason(action.to_sym))
    end

    def validate_vm_for_remote_console(vm, protocol = nil)
      protocol ||= "mks"
      vm.validate_remote_console_acquire_ticket(protocol)
      action_result(true, "")
    rescue MiqException::RemoteConsoleNotSupportedError => err
      action_result(false, err.message)
    end

    def set_owner_vm(vm, owner)
      desc = "#{vm_ident(vm)} setting owner to '#{owner}'"
      user = User.lookup_by_identity(owner)
      raise "Invalid user #{owner} specified" unless user
      vm.evm_owner = user
      vm.miq_group = user.current_group unless user.nil?
      vm.save!
      action_result(true, desc)
    rescue => err
      action_result(false, err.to_s)
    end

    def add_lifecycle_event_vm(vm, lifecycle_event)
      desc = "#{vm_ident(vm)} adding lifecycle event=#{lifecycle_event['event']} message=#{lifecycle_event['message']}"
      event = LifecycleEvent.create_event(vm, lifecycle_event)
      action_result(event.present?, desc)
    rescue => err
      action_result(false, err.to_s)
    end

    def lifecycle_event_from_data(data)
      data ||= {}
      data = data.slice("event", "status", "message", "created_by")
      data.keys.each { |k| data[k] = data[k].to_s }
      data
    end

    def vm_event(vm, event_type, event_message, event_time)
      desc = "Adding Event type=#{event_type} message=#{event_message}"
      event_timestamp = event_time.blank? ? Time.now.utc : event_time.to_time(:utc)

      vm.add_ems_event(event_type, event_message, event_timestamp)
      action_result(true, desc)
    rescue => err
      action_result(false, err.to_s)
    end

    def rename_vm(vm, new_name)
      desc = "#{vm_ident(vm)} renaming to #{new_name}"
      task_id = vm.rename_queue(User.current_user.userid, new_name)
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def set_description_vm(vm, new_description)
      desc = "#{vm_ident(vm)} setting description to #{new_description}"
      task_id = vm.set_description_queue(User.current_user.userid, new_description)
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end
  end
end
