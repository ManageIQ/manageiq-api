module Api
  class MetricRollupsController < BaseController
    REQUIRED_PARAMS = %w(resource_type capture_interval start_date).freeze

    def index
      validate_params
      params[:offset] ||= 0
      params[:limit]  ||= Settings.api.metrics_default_limit

      start_date = params[:start_date].to_date
      end_date = params[:end_date].try(:to_date)

      resources = MetricRollup.rollups_in_range(params[:resource_type], params[:resource_ids], params[:capture_interval], start_date, end_date)
      res = collection_filterer(resources, :metric_rollups, MetricRollup).flatten
      counts = Api::QueryCounts.new(MetricRollup.count, res.count, resources.count)

      render_collection(:metric_rollups, res, :counts => counts, :expand_resources => @req.expand?(:resources))
    end

    private

    def validate_params
      REQUIRED_PARAMS.each do |key|
        raise BadRequestError, "Must specify #{REQUIRED_PARAMS.join(', ')}" unless params[key.to_sym]
      end

      unless MetricRollup::CAPTURE_INTERVAL_NAMES.include?(params[:capture_interval])
        raise BadRequestError, "Capture interval must be one of #{MetricRollup::CAPTURE_INTERVAL_NAMES.join(', ')}"
      end
    end
  end
end
