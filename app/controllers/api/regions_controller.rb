module Api
  class RegionsController < BaseController
    INVALID_REGIONS_ATTRS = %w(id created_on updated_on).freeze

    def edit_resource(type, id, data)
      bad_attrs = data_includes_invalid_attrs(data)
      if bad_attrs.present?
        raise BadRequestError, "Attributes #{bad_attrs} should not be specified for updating a region resource"
      end
      super
    end
  end
end
