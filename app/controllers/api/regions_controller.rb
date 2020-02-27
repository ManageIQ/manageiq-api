module Api
  class RegionsController < BaseController
    INVALID_REGIONS_ATTRS = ID_ATTRS + %w[created_at updated_at region guid migrations_ran maintenance_zone_id].freeze

    # Edit an existing region (MiqRegion). Certain fields are meant for
    # internal use only and may not be edited. Attempting to edit one of
    # the forbidden fields will result in a bad request error.
    #
    def edit_resource(type, id, data)
      bad_attrs = data_includes_invalid_attrs(data)

      if bad_attrs.present?
        msg = "Attribute(s) '#{bad_attrs}' should not be specified for updating a region resource"
        raise BadRequestError, msg
      end

      super
    end

    private

    # Check to see if any of the data attributes contain an invalid field.
    # Returns a list of invalid fields as a comma separated string that you
    # can use for error messages, or nil if the data argument is blank.
    #
    def data_includes_invalid_attrs(data)
      return nil unless data

      data.keys.select { |key| INVALID_REGIONS_ATTRS.include?(key) }.compact.join(", ")
    end
  end
end
