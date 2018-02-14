module Api
  class MetricRollupsService
    REQUIRED_PARAMS = %w(resource_type capture_interval start_date).freeze
    QUERY_PARAMS = %w(resource_ids).freeze

    attr_reader :params

    def initialize(params)
      @params = params.slice(*(REQUIRED_PARAMS + QUERY_PARAMS))
      validate_required_params
      validate_capture_interval
    end

    def query_metric_rollups
      start_date = params[:start_date].to_date
      end_date = params[:end_date].try(:to_date)

      MetricRollup.rollups_in_range(params[:resource_type], params[:resource_ids], params[:capture_interval], start_date, end_date)
    end

    private

    def validate_required_params
      not_specified = REQUIRED_PARAMS - params.keys
      raise BadRequestError, "Must specify #{not_specified.join(', ')}" unless not_specified.empty?
    end

    def validate_capture_interval
      unless MetricRollup::CAPTURE_INTERVAL_NAMES.include?(params[:capture_interval])
        raise BadRequestError, "Capture interval must be one of #{MetricRollup::CAPTURE_INTERVAL_NAMES.join(', ')}"
      end
    end
  end
end
