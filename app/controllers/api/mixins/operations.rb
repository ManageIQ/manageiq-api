module Api
  module Mixins
    #
    # Contains the routines to enqueue operations for resources
    #
    module Operations
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

        resource = resource_search(id, type, collection_class(type))

        api_action(type, id) do
          begin
            desc = "Performing #{action} for #{resource_identify(resource)}"
            api_log_info(desc)
            task_id = queue_object_action(resource, desc, :method_name => action, :role => :ems_operations)
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

      #
      # Mounts a string to identify the resource that is
      #   performing the operation.
      #
      # @param resource - resource that is performing the operation.
      #
      def resource_identify(resource)
        "#{resource.class.name.demodulize.underscore.humanize} id:#{resource.id} name: '#{resource.name}'"
      end
    end
  end
end
