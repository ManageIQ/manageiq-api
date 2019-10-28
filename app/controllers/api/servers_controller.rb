module Api
  class ServersController < BaseController
    INVALID_SERVERS_ATTRS = ID_ATTRS + %w[
      started_on
      stopped_on
      percent_memory
      percent_cpu
      cpu_time
      memory_usage
      memory_size
      proportional_set_size
      system_memory_free
      system_memory_used
      system_swap_free
      system_swap_used
      unique_set_size
    ].freeze

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

      data.keys.select { |key| INVALID_SERVERS_ATTRS.include?(key) }.compact.join(", ")
    end
  end
end
