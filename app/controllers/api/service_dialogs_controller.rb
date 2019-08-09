module Api
  class ServiceDialogsController < BaseController
    before_action :set_additional_attributes, :only => [:index, :show]

    CONTENT_PARAMS = %w[target_type target_id resource_action_id].freeze
    TEMPLATE_DIALOG_ATTRS = %w[template_id label template_class dialog_class].freeze
    TEMPLATE_CLASSES = %w[OrchestrationTemplate ConfigurationScript].freeze
    DIALOG_CLASSES = %w[Dialog::OrchestrationTemplateServiceDialog Dialog::AnsibleTowerJobTemplateDialogService].freeze


    def refresh_dialog_fields_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for Reconfiguring a #{type} resource" unless id

      api_action(type, id) do |klass|
        service_dialog = resource_search(id, type, klass)
        api_log_info("Refreshing Dialog Fields for #{service_dialog_ident(service_dialog)}")

        refresh_dialog_fields_service_dialog(service_dialog, data)
      end
    end

    def fetch_service_dialogs_content(resource)
      target, resource_action = validate_dialog_content_params(params)
      resource.content(target, resource_action, true)
    end

    def create_resource(_type, _id, data)
      dialog = DialogImportService.new.import(data)
      fetch_service_dialogs_content(dialog).first
    rescue => e
      raise BadRequestError, "Failed to create a new dialog - #{e}"
    end

    def edit_resource(type, id, data)
      service_dialog = resource_search(id, type, Dialog)
      begin
        $api_log.warn("Both 'dialog_tabs':[...] and 'content':{'dialog_tabs':[...]} were specified. 'content':{'dialog_tabs':[...]} will be ignored.") if data.key?('dialog_tabs') && data['content'].try(:key?, 'dialog_tabs')
        service_dialog.update_tabs(data['dialog_tabs'] || data['content']['dialog_tabs']) if data['dialog_tabs'] || data['content']
        service_dialog.update!(data.except('dialog_tabs', 'content'))
      rescue => err
        raise BadRequestError, "Failed to update service dialog - #{err}"
      end
      fetch_service_dialogs_content(service_dialog).first
    end

    def copy_resource(type, id, data)
      service_dialog = resource_search(id, type, Dialog)
      attributes = data.dup
      attributes['label'] = "Copy of #{service_dialog.label}" unless attributes.key?('label')
      service_dialog.deep_copy(attributes).tap(&:save!)
    rescue => err
      raise BadRequestError, "Failed to copy service dialog - #{err}"
    end

    def template_service_dialog_resource(_type, _id, data)
      validate_template_dialog_create_data(data)
      template = data['template_class'].constantize.find(data['template_id'])
      raise BadRequestError, "Failed to create service dialog from template. Template with id: #{data['template_id']} does not exist." unless template

      data['dialog_class'].constantize.create_dialog(data['label'], template)
    end

    private

    def validate_dialog_content_params(params, required = false)
      return unless CONTENT_PARAMS.detect { |param| params.include?(param) } || required

      raise BadRequestError, "Must specify all of #{CONTENT_PARAMS.join(',')}" unless (CONTENT_PARAMS - params.keys).count.zero?
      type = collection_config.name_for_subclass(params['target_type'].camelize)
      raise BadRequestError, "Invalid target_type #{params['target_type']}" unless type

      target = resource_search(params['target_id'], type, collection_class(type))
      resource_action = resource_search(params['resource_action_id'], :resource_actions, ResourceAction)
      [target, resource_action]
    end

    def set_additional_attributes
      @additional_attributes = %w(content) if attribute_selection == "all"
    end

    def refresh_dialog_fields_service_dialog(dialog, data)
      data ||= {}
      dialog_fields = Hash(data["dialog_fields"])
      refresh_fields = data["fields"]
      return action_result(false, "Must specify fields to refresh") if refresh_fields.blank?

      service_dialog = define_service_dialog(dialog_fields, data, {:refresh => true})

      if service_dialog.id != dialog.id
        return action_result(
          false,
          "Dialog from resource action and requested refresh dialog must be the same dialog"
        )
      end

      refresh_dialog_fields_action(service_dialog, refresh_fields, service_dialog_ident(service_dialog))
    rescue => err
      action_result(false, err.to_s)
    end

    def define_service_dialog(dialog_fields, data, options = {})
      target, resource_action = validate_dialog_content_params(data, true)

      workflow = ResourceActionWorkflow.new({}, User.current_user, resource_action, {:target => target}.merge(options))

      dialog_fields.each { |key, value| workflow.set_value(key, value) }
      workflow.dialog
    end

    def service_dialog_ident(service_dialog)
      "Service Dialog id:#{service_dialog.id} label:'#{service_dialog.label}'"
    end

    def validate_template_dialog_create_data(data)
      missing_attributes = TEMPLATE_DIALOG_ATTRS - data.keys
      raise BadRequestError, "Missing attribute(s) #{missing_attributes.join(', ')} for creating a service dialog from template" if missing_attributes.present?

      invalid_attributes = data.keys - TEMPLATE_DIALOG_ATTRS
      raise BadRequestError, "Invalid attribute(s) #{invalid_attributes.join(', ')} for creating a service dialog from template" if invalid_attributes.present?

      raise BadRequestError, "Invalid template_class #{data['template_class']} for creating a service dialog from template" unless TEMPLATE_CLASSES.include?(data['template_class'])
      raise BadRequestError, "Invalid dialog_class #{data['dialog_class']} for creating a service dialog from template" unless DIALOG_CLASSES.include?(data['dialog_class'])
    end

    def api_resource_action_options
      if @req.action == "refresh_dialog_fields" && @req.collection_id && @req.subcollection.blank?
        %w[include_encrypted_attributes]
      else
        super
      end
    end
  end
end
