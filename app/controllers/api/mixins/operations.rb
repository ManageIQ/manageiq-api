module Api
  module Mixins
    #
    # Contains the routines to enqueue operations for resources
    #
    module Operations
      #
      # Enqueue an action to be performed.
      #   For multiple resources, when an error occurs, the error messages must
      #   be built individually for each resource. Always responding with status 200.
      #
      # @param [symbol] type           - type of the resource
      # @param [number] id             - id of the resource
      # @param [String] action_phrase  - descriptive phrase for action (default: Performing )
      # @param [Hash] options          - options for the queue message
      # @option options :method_name   - method name for the queue
      # @option options :args          - args for the queue method
      # @option options :role          - role for queue (defaults: ems_operations)
      def enqueue_action(type, id, action_phrase = nil, options = {})
        if action_phrase.kind_of?(Hash)
          options = action_phrase
          action_phrase ||= "Performing #{args[:method_name]} for "
        end

        options[:role] ||= "ems_operations"
        api_resource(type, id, action_phrase) do |model|
          yield(model) if block_given?
          desc = "#{action_phrase} #{model_ident(model, type)}"
          {:task_id => queue_object_action(model, desc, options)}
        end
      end
    end
  end
end
