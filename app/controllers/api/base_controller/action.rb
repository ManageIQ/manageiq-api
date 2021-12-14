module Api
  class BaseController
    module Action
      private

      def api_action(type, id)
        result = yield(collection_class(type))
        add_href_to_result(result, type, id) unless result[:href]
        log_result(result)
        result
      end

      # wrapper around api_action than adds a few things:
      #
      # - enforces id exists
      # - constructs action_result for successes and failures
      # - throws errors for single resources and use results for multiple resoruces
      def api_resource(type, id, action_phrase)
        api_action(type, id) do
          id ||= @req.collection_id
          raise BadRequestError, "#{action_phrase} #{type.to_s.titleize} requires an id" unless id

          api_log_info("#{action_phrase} #{type.to_s.titleize} id: #{id}")
          resource = resource_search(id, type)
          result_options = yield(resource)
          if result_options.key?(:success) # full action hash (finer grained messaging)
            result_options
          else # result_options is action_hash (preferred)
            action_result(true, "#{action_phrase} #{model_ident(resource, type)}", result_options)
          end
        rescue ActiveRecord::RecordNotFound, ForbiddenError, BadRequestError, NotFoundError => err
          single_resource? ? raise : action_result(false, err.to_s)
        rescue => err
          action_result(false, err.to_s)
        end
      end

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
      # @option options :supports      - check that this method_name is supported by the model
      def enqueue_action(type, id, action_phrase = nil, options = {})
        if action_phrase.kind_of?(Hash)
          options = action_phrase
          action_phrase = nil
        end
        action_phrase ||= "Performing #{options[:method_name]} for "

        supports = options.delete(:supports)
        supports = options[:method_name] if supports == true

        api_resource(type, id, action_phrase) do |model|
          ensure_supports(type, model, options[:method_name], supports) if supports
          yield(model) if block_given?
          desc = "#{action_phrase} #{model_ident(model, type)}"
          {:task_id => queue_object_action(model, desc, options)}
        end
      end

      def enqueue_ems_action(type, id, action_phrase = nil, options = {}, &block)
        if action_phrase.kind_of?(Hash)
          options = action_phrase
          action_phrase = nil
        end
        options.reverse_merge!(:role => "ems_operations", :user => true)
        enqueue_action(type, id, action_phrase, options, &block)
      end

      def queue_object_action(object, summary, options)
        user = User.current_user
        task_options = {
          :action => summary,
          :userid => user.userid
        }

        queue_options = {
          :class_name  => options[:class_name] || object.class.name,
          :method_name => options[:method_name],
          :instance_id => object.id,
          :args        => options[:args] || [],
          :role        => options[:role] || nil,
        }

        if options[:user]
          queue_options[:user_id]   = user.id
          queue_options[:group_id]  = user.current_group.id
          queue_options[:tenant_id] = user.current_tenant.id
        end
        queue_options[:zone] = object.my_zone if %w(ems_operations smartstate).include?(options[:role])

        MiqTask.generic_action_with_callback(task_options, queue_options)
      end
    end
  end
end
