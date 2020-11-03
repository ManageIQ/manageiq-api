module Api
  class MetricRollupsService
    REQUIRED_FILTER_PARAMETERS = %w(resource_type capture_interval start_date).freeze
    QUERY_FILTER_PARAMETERS = %w(resource_ids end_date).freeze

    attr_reader :filter_parameters

    def initialize(parameters)
      @filter_parameters = parameters.slice(*(REQUIRED_FILTER_PARAMETERS + QUERY_FILTER_PARAMETERS))
      validate_required_filter_parameters
      validate_capture_interval
    end

    def query_metric_rollups
      start_date = filter_parameters[:start_date].to_date
      end_date = filter_parameters[:end_date].try(:to_date)
      MetricRollup.rollups_in_range(filter_parameters[:resource_type], filter_parameters[:resource_ids], filter_parameters[:capture_interval], start_date, end_date)
    end

    private

    def validate_required_filter_parameters
      not_specified = REQUIRED_FILTER_PARAMETERS - filter_parameters.keys
      raise BadRequestError, "Must specify #{not_specified.join(', ')}" unless not_specified.empty?
    end

    def validate_capture_interval
      unless MetricRollup::CAPTURE_INTERVAL_NAMES.include?(filter_parameters[:capture_interval])
        raise BadRequestError, "Capture interval must be one of #{MetricRollup::CAPTURE_INTERVAL_NAMES.join(', ')}"
      end
    end
  end
end
