module Api
  class BaseController
    module Generic
      #
      # Action Helper Methods
      #
      # Name: <action>_resource
      # Args: collection type, resource id, optional data
      #
      # For type specified, name is <action>_resource_<collection>
      # Same signature.
      #
      def add_resource(type, _id, data)
        assert_id_not_specified(data, "#{type} resource")
        klass = collection_class(type)
        extract_subcollection_data!(collection_config.subcollections(type), data)
        validate_type(klass, data['type']) if data['type']
        resource = klass.new(data)
        if resource.save
          add_subcollection_data_to_resource(resource, type)
          resource
        else
          raise BadRequestError, "Failed to add a new #{type} resource - #{resource.errors.full_messages.join(', ')}"
        end
      end

      alias create_resource add_resource

      def query_resource(type, id, data)
        unless id
          data_spec = data.collect { |key, val| "#{key}=#{val}" }.join(", ")
          raise NotFoundError, "Invalid #{type} resource specified - #{data_spec}"
        end
        resource = resource_search(id, type)
        opts = {
          :name                  => type.to_s,
          :is_subcollection      => false,
          :expand_resources      => true,
          :expand_actions        => true,
          :expand_custom_actions => true
        }
        resource_to_jbuilder(type, type, resource, opts).attributes!
      end

      def edit_resource(type, id, data)
        resource = resource_search(id, type)
        resource.update!(data.except(*ID_ATTRS))
        resource
      end

      def delete_resource(type, id = nil, data = nil)
        delete_resource_action(type, id, data)
      end

      def request_retire_resource(type, id, data = nil)
        klass = collection_class(type)
        if id
          msg = "#{User.current_user.userid} retiring #{type} id #{id} as a request"
          resource = resource_search(id, type, klass)
          if data && data["date"]
            opts = {}
            opts[:date] = data["date"]
            opts[:warn] = data["warn"] if data["warn"]
            msg << " on: #{opts}"
            api_log_info(msg)
            resource.retire(opts)
          else
            msg << " immediately."
            api_log_info(msg)
            klass.make_retire_request(resource.id, User.current_user)
          end
        else
          raise BadRequestError, "Must specify an id for retiring a #{type} resource"
        end
      end

      def retire_resource(type, id, data = nil)
        if id
          msg = "Retiring #{type} id #{id}"
          resource = resource_search(id, type)
          if data && data["date"]
            opts = {}
            opts[:date] = data["date"]
            opts[:warn] = data["warn"] if data["warn"]
            msg << " on: #{opts}"
            api_log_info(msg)
            resource.retire(opts)
          else
            msg << " immediately."
            api_log_info(msg)
            resource.retire_now
          end
          resource
        else
          raise BadRequestError, "Must specify an id for retiring a #{type} resource"
        end
      end
      alias generic_retire_resource retire_resource

      def custom_action_resource(type, id, data = nil)
        action = @req.action.downcase
        id ||= @req.collection_id
        if id.blank?
          raise BadRequestError, "Must specify an id for invoking the custom action #{action} on a #{type} resource"
        end

        api_log_info("Invoking #{action} on #{type} id #{id}")
        resource = resource_search(id, type)
        unless resource_custom_action_names(resource).include?(action)
          raise BadRequestError, "Unsupported Custom Action #{action} for the #{type} resource specified"
        end
        invoke_custom_action(type, resource, action, data)
      end

      def set_ownership_resource(type, id, data = nil)
        raise BadRequestError, "Must specify an id for setting ownership of a #{type} resource" unless id
        raise BadRequestError, "Must specify an owner or group for setting ownership data = #{data}" if data.blank?

        api_action(type, id) do |klass|
          resource_search(id, type, klass)
          api_log_info("Setting ownership to #{type} #{id}")
          ownership = parse_ownership(data)
          set_ownership_action(klass, type, id, ownership)
        end
      end

      def refresh_dialog_fields_action(dialog, refresh_fields, resource_ident)
        result = {}
        refresh_fields.each do |field|
          dynamic_field = dialog.field(field)
          return action_result(false, "Unknown dialog field #{field} specified") unless dynamic_field
          result[field] = dynamic_field.update_and_serialize_values
        end
        action_result(true, "Refreshing dialog fields for #{resource_ident}", :result => result)
      end

      private

      def extract_subcollection_data!(subcollections, data)
        @subcollection_data ||= subcollections.each_with_object({}) do |sc, hash|
          if data.key?(sc.to_s)
            hash[sc] = data[sc.to_s]
            data.delete(sc.to_s)
          end
        end
      end

      def validate_type(klass, type)
        klass.descendant_get(type)
      rescue ArgumentError => err
        raise BadRequestError, "Invalid type #{type} specified - #{err}"
      end

      def add_subcollection_data_to_resource(resource, type)
        @subcollection_data.each do |sc, sc_data|
          typed_target = "#{sc}_assign_resource"
          raise BadRequestError, "Cannot assign #{sc} to a #{type} resource" unless respond_to?(typed_target)
          sc_data.each do |sr|
            next if sr.blank?
            href = Href.new(sr["href"])
            if href.subject == sc && href.subject_id
              sr.delete("id")
              sr.delete("href")
            end
            send(typed_target, resource, type, href.subject_id.to_i, sr)
          end
        end
      end

      # called by default delete_resource, (but some other dynamic methods as well)
      # majority of these return an action hash
      # Unfortunately, some sub-collections return an object
      # making the transition to all returning an action hash
      def delete_resource_action(type, id = nil, data = nil)
        api_resource(type, id, "Deleting") do |resource|
          delete_resource_main_action(type, resource, data)
        end
      end

      # The lower-level implementation for deleting a resource.
      #
      # The default implementation here will delete the record directly from the database.
      #   It is expected that subclasses will override for alternative delete strategies,
      #   for example to delete via the native provider over the queue.
      def delete_resource_main_action(_type, resource, _data)
        resource.destroy!
        {}
      end

      def invoke_custom_action(type, resource, action, data)
        custom_button = resource_custom_action_button(resource, action)
        if custom_button.resource_action.dialog_id
          return invoke_custom_action_with_dialog(type, resource, action, data, custom_button)
        end

        api_action(type, resource.id) do
          custom_button.invoke(resource)
          action_result(true, "Invoked custom action #{action} for #{type} id: #{resource.id}")
        rescue => err
          action_result(false, err.to_s)
        end
      end

      def invoke_custom_action_with_dialog(type, resource, action, data, custom_button)
        api_action(type, resource.id) do
          custom_button.publish_event(nil, resource)
          wf_result = submit_custom_action_dialog(resource, custom_button, data)
          action_result(true,
                        "Invoked custom dialog action #{action} for #{type} id: #{resource.id}",
                        :result => wf_result[:request], :task_id => wf_result[:task_id])
        rescue => err
          action_result(false, err.to_s)
        end
      end

      def submit_custom_action_dialog(resource, custom_button, data)
        wf = ResourceActionWorkflow.new({}, User.current_user, custom_button.resource_action, :target => resource)
        wf_result = wf.submit_request(data)
        raise StandardError, Array(wf_result[:errors]).join(", ") if wf_result[:errors].present?
        wf_result
      end

      def resource_custom_action_button(resource, action)
        resource.custom_action_buttons.find { |b| b.name.downcase == action.downcase }
      end

      def set_ownership_action(klass, type, id, ownership)
        if ownership.blank?
          action_result(false, "Must specify a valid owner or group for setting ownership")
        else
          result = klass.set_ownership([id], ownership)
          details = ownership.each.collect { |key, obj| "#{key}: #{obj.name}" }.join(", ")
          desc = "setting ownership of #{type} id #{id} to #{details}"
          result == true ? action_result(true, desc) : action_result(false, result.values.join(", "))
        end
      rescue => err
        action_result(false, err.to_s)
      end

      def model_ident(model, type = nil)
        if model.respond_to?(:name)
          "#{type.to_s.singularize.titleize} id: #{model.id} name: '#{model.name}'"
        else
          "#{type.to_s.singularize.titleize} id: #{model.id}"
        end
      end

      def validate_id(id, key_id, klass)
        if id.nil? || (key_id == "id" && !id.integer?)
          raise BadRequestError, "Invalid #{klass} #{key_id} #{id || "nil"} specified"
        end
      end
    end
  end
end
