module Api
  class MetricRollupsService
    REQUIRED_PARAMS = %w(resource_type capture_interval start_date).freeze

    def self.query_metric_rollups(params)
      validate_params(params)

      params[:offset] ||= 0
      params[:limit] ||= Settings.api.metrics_default_limit

      start_date = params[:start_date].to_date
      end_date = params[:end_date].try(:to_date)

      MetricRollup.rollups_in_range(params[:resource_type], params[:resource_ids], params[:capture_interval], start_date, end_date)
    end

    def self.validate_params(params)
      REQUIRED_PARAMS.each do |key|
        raise BadRequestError, "Must specify #{REQUIRED_PARAMS.join(', ')}" unless params[key.to_sym]
      end

      unless MetricRollup::CAPTURE_INTERVAL_NAMES.include?(params[:capture_interval])
        raise BadRequestError, "Capture interval must be one of #{MetricRollup::CAPTURE_INTERVAL_NAMES.join(', ')}"
      end
    end
    private_class_method :validate_params
  end
end
