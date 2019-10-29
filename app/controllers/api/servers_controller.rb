module Api
  class ServersController < BaseController
    VALID_SERVERS_ATTRS = %w[name zone].freeze

    # Edit an existing server (MiqServer). Certain fields are meant for
    # internal use only and may not be edited. Attempting to edit one of
    # the forbidden fields will result in a bad request error.
    #
    def edit_resource(type, id, data)
      bad_attrs = data_includes_invalid_attrs(data)

      if bad_attrs.present?
        msg = "Attribute(s) '#{bad_attrs}' should not be specified for updating a server resource"
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

      (data.keys - VALID_SERVERS_ATTRS).compact.join(', ')
    end
  end
end
