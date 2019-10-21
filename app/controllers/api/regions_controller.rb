module Api
  class RegionsController < BaseController
    INVALID_REGIONS_ATTRS = %w(id created_at updated_at).freeze

    def edit_resource(type, id, data)
      bad_attrs = data_includes_invalid_attrs(data)

      if bad_attrs.present?
        msg = "Attributes #{bad_attrs} should not be specified for updating a region resource"
        raise BadRequestError, msg
      end

      super
    end

    private

    def data_includes_invalid_attrs(data)
      return nil unless data
      data.keys.select { |key| INVALID_REGIONS_ATTRS.include?(key) }.compact.join(", ")
    end
  end
end
