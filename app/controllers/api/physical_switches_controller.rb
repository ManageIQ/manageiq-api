module Api
  class PhysicalSwitchesController < BaseController
    def refresh_resource(type, id, _data = nil)
      raise BadRequestError, "Must specify an id for refreshing a #{type} resource" unless id

      ensure_resource_exists(type, id) if single_resource?

      api_action(type, id) do |klass|
        physical_switch = resource_search(id, type, klass)
        api_log_info("Refreshing #{physical_switch_ident(physical_switch)}")
        refresh_physical_switch(physical_switch)
      end
    end

    def restart_resource(type, id, _data = nil)
      perform_action(:restart, type, id)
    end

    private

    def perform_action(action, type, id)
      if single_resource?
        enqueue_action_single_resource(action, type, id)
      else
        enqueue_action_multiple_resources(action, type, id)
      end
    end

    #
    # Enqueues the action for a single resource.
    #
    # @param [symbol] action - action to be enqueued
    # @param [symbol] type   - type of the resource
    # @param [number] id     - id of the resource
    #
    def enqueue_action_single_resource(action, type, id)
      raise BadRequestError, "Must specify an id for changing a #{type} resource" unless id

      physical_switch = resource_search(id, type, collection_class(type))

      api_action(type, id) do
        begin
          desc = "Performing #{action} for #{physical_switch_ident(physical_switch)}"
          api_log_info(desc)
          task_id = queue_object_action(physical_switch, desc, :method_name => action, :role => :ems_operations)
          action_result(true, desc, :task_id => task_id)
        rescue StandardError => err
          action_result(false, err.to_s)
        end
      end
    end

    #
    # Enqueues the action for multiple resources.
    #   For multiple resources, when an error occurs, the error messages must
    #   be built individually for each resource. Always responding with status 200.
    #
    # @param [symbol] action - action to be enqueued
    # @param [symbol] type   - type of the resource
    # @param [number] id     - id of the resource
    #
    def enqueue_action_multiple_resources(action, type, id)
      enqueue_action_single_resource(action, type, id)
    rescue ActiveRecord::RecordNotFound => err
      action_result(false, _(err.message))
    end

    def ensure_resource_exists(type, id)
      raise NotFoundError, "#{type} with id:#{id} not found" unless collection_class(type).exists?(id)
    end

    def refresh_physical_switch(physical_switch)
      desc = "#{physical_switch_ident(physical_switch)} refreshing"
      task_id = queue_object_action(physical_switch, desc, :method_name => "refresh_ems", :role => "ems_operations")
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def physical_switch_ident(physical_switch)
      "Physical Switch id:#{physical_switch.id} name: '#{physical_switch.name}'"
    end
  end
end
