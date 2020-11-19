module Api
  class WidgetSetsController < BaseController
    REQUIRED_FIELDS_TO_COPY = %w[name].freeze
    ALLOWED_FIELDS = REQUIRED_FIELDS_TO_COPY + %w[group description guid read_only set_data].freeze

    def create_resource(type, id = nil, data = nil)
      raise_if_unsupported_fields_passed(data)

      data['group_id'] = parse_resource_from(data.delete('group'))
      data['owner_id'] = data['group_id']
      super(type, id, data)
    end

    def edit_resource(type, id = nil, data = nil)
      raise_if_unsupported_fields_passed(data, ALLOWED_FIELDS - %w[name group])

      super(type, id, data)
    end

    def delete_resource(type, id = nil, data = nil)
      klass = collection_class(type)
      widget_set = resource_search(id, type, klass)
      raise ArgumentError, "Unable to delete read_only widget_set" if widget_set.read_only?

      api_action(type, id) do |_klass|
        super(type, id, data)

        action_result(true, "Dashboard #{widget_set.name} has been successfully deleted.")
      end
    end

    def copy_resource(type, id = nil, data = nil)
      raise_if_unsupported_fields_passed(data)

      klass = collection_class(type)
      widget_set = resource_search(id, type, klass)
      group_id = parse_resource_from(data['group']) || widget_set.group_id

      widget_set = MiqWidgetSet.copy_dashboard(widget_set, data['name'], data['description'], group_id)

      result = action_result(true, "Dashboard #{data['name']} successfully created.")
      add_href_to_result(result, type, widget_set.id)
      result
    end

    private

    def parse_resource_from(attributes)
      return unless attributes

      attributes['id']&.to_i || (attributes['href'] && Api::Href.new(attributes['href']).subject_id) if attributes
    end

    def raise_if_unsupported_fields_passed(data, allowed_fields = ALLOWED_FIELDS)
      unsupported_fields = data.keys - allowed_fields
      raise BadRequestError, "Field(s) #{unsupported_fields.join(", ")} are not supported" if unsupported_fields.present?
    end
  end
end
