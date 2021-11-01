module Api
  class BaseController
    module Action
      private

      def api_action(type, id, options = {})
        klass = collection_class(type)

        result = yield(klass) if block_given?

        add_href_to_result(result, type, id) unless options[:skip_href]
        log_result(result)
        result
      end

      # wrapper around api_action than adds a few things:
      #
      # - enforces id exists
      # - constructs action_result for successes and failures
      # - throws errors for single resources and use results for multiple resoruces
      def api_resource(type, id, action_phrase)
        id ||= @req.collection_id
        klass = collection_class(type)
        raise BadRequestError, "#{action_phrase} #{type.to_s.titleize} requires an id" unless id

        api_log_info("#{action_phrase} #{type.to_s.titleize} id: #{id}")
        resource = resource_search(id, type, klass)
        result_options = yield(resource)
        result = action_result(true, "#{action_phrase} #{model_ident(resource, type)}", result_options)
        add_href_to_result(result, type, id)
        log_result(result)
        result
      rescue ActiveRecord::RecordNotFound, ForbiddenError, BadRequestError, NotFoundError => err
        single_resource? ? raise : action_result(false, err.to_s)
      rescue => err
        action_result(false, err.to_s)
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

      def queue_object_action(object, summary, options)
        task_options = {
          :action => summary,
          :userid => User.current_user.userid
        }

        queue_options = {
          :class_name  => options[:class_name] || object.class.name,
          :method_name => options[:method_name],
          :instance_id => object.id,
          :args        => options[:args] || [],
          :role        => options[:role] || nil,
        }

        queue_options.merge!(options[:user]) if options.key?(:user)
        queue_options[:zone] = object.my_zone if %w(ems_operations smartstate).include?(options[:role])

        MiqTask.generic_action_with_callback(task_options, queue_options)
      end

      def queue_options(method, role = nil)
        {
          :method_name => method,
          :role        => role,
          :user        => {
            :user_id   => current_user.id,
            :group_id  => current_user.current_group.id,
            :tenant_id => current_user.current_tenant.id
          }
        }
      end
    end
  end
end
