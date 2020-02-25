module Api
  class AutomateClassesController < BaseController
    EDITABLE_ATTRS = %w[name display_name description].freeze

    def edit_resource(type, id, data)
      bad_attrs = data_includes_invalid_attrs(data)

      if bad_attrs.present?
        msg = "Attribute(s) '#{bad_attrs}' should not be specified for updating an automate class resource"
        raise BadRequestError, msg
      end

      super
    end

    private

    def data_includes_invalid_attrs(data)
      return nil unless data

      data.keys.reject { |key| EDITABLE_ATTRS.include?(key) }.compact.join(", ")
    end
  end
end
