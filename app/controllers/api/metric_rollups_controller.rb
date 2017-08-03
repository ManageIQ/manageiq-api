module Api
  class MetricRollupsController < BaseController
    REQUIRED_PARAMS = %w(resource_type capture_interval start_date).freeze

    def index
      validate_params

      start_date = params[:start_date].to_date
      end_date = params[:end_date].nil? ? Time.zone.today : params[:end_date].to_date
      interval = (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
      validate_dates(interval)

      resources = MetricRollup.rollups_in_range(params[:resource_type], params[:resource_ids], params[:capture_interval], start_date, end_date)
      counts = Api::QueryCounts.new(MetricRollup.count, resources.count)

      render_collection(:metric_rollups, resources, :counts => counts)
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

    def validate_dates(interval)
      case params[:capture_interval]
      when 'hourly'
        raise BadRequestError, "Can only return hourly records in two month intervals" if interval > 2
      when 'daily'
        raise BadRequestError, "Can only return daily records in 24 month intervals" if interval > 24
      end
    end
  end
end
