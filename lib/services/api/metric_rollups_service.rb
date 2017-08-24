module Api
  class MetricRollupsService
    REQUIRED_PARAMS = %w(resource_type capture_interval start_date).freeze

    attr_reader :params

    def initialize(params)
      @params = params
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
      REQUIRED_PARAMS.each do |key|
        raise BadRequestError, "Must specify #{REQUIRED_PARAMS.join(', ')}" unless params[key.to_sym]
      end
    end

    def validate_capture_interval
      unless MetricRollup::CAPTURE_INTERVAL_NAMES.include?(params[:capture_interval])
        raise BadRequestError, "Capture interval must be one of #{MetricRollup::CAPTURE_INTERVAL_NAMES.join(', ')}"
      end
    end
  end
end
