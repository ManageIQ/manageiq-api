module Api
  class MetricsService
    REQUIRED_FILTER_PARAMETERS = %w[resource_type start_date].freeze
    QUERY_FILTER_PARAMETERS = %w[resource_ids end_date].freeze

    attr_reader :filter_parameters

    def initialize(parameters)
      @filter_parameters = parameters.slice(*(REQUIRED_FILTER_PARAMETERS + QUERY_FILTER_PARAMETERS))
      validate_required_filter_parameters
    end

    def query_metrics
      start_date = filter_parameters[:start_date].to_date
      end_date   = filter_parameters[:end_date].try(:to_date)
      Metric.metrics_in_range(filter_parameters[:resource_type], filter_parameters[:resource_ids], start_date, end_date)
    end

    private

    def validate_required_filter_parameters
      not_specified = REQUIRED_FILTER_PARAMETERS - filter_parameters.keys
      raise BadRequestError, "Must specify #{not_specified.join(', ')}" unless not_specified.empty?
    end
  end
end
