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

      def create_resource_task_result(type, ems_id, options = {}, &block)
        raise BadRequestError, "Must specify a valid provider id" unless ems_id
        ems = resource_search(ems_id, :ext_management_systems, ExtManagementSystem)
        klass = collection_class(type).class_by_ems(ems)
        raise BadRequestError, "Create #{type.to_s.titleize} for Provider #{ems.name}: #{klass.unsupported_reason(:create)}" unless klass.supports?(:create)

        task_id = block&.arity == 2 ? yield(ems, klass) : yield(ems)

        action_result(true, "Creating #{type.to_s.titleize} #{options[:name]} for Provider: #{ems.name}", :task_id => task_id)
      rescue => err
        action_result(false, err.to_s)
      end

      # @param action :update, :delete, :refresh
      def resource_task_result(type, id, action, options = {})
        action_phrase = {:update => 'Updating', :delete => 'Deleting', :refresh => 'Refreshing'}[action] || action
        raise BadRequestError, "#{action_phrase} #{type} requires an id" unless id

        model = resource_search(id, type, collection_class(type))
        raise BadRequestError, "#{action.to_s.titleize} for #{type.to_s.titleize}: #{model.unsupported_reason(action)}" unless model.supports?(action)

        task_id = yield(model)

        message = options[:message] || "#{action_phrase} #{model_ident(model)}"
        action_result(true, message, :task_id => task_id)
      rescue ActiveRecord::RecordNotFound => err
        single_resource? ? raise(err) : action_result(false, err.to_s)
      rescue => err
        action_result(false, err.to_s)
      end

      def model_ident(model)
        "#{model.class.base_class.name.titleize} id: #{model.id} name: '#{model.name}'"
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
