module Api
  class MetricRollupsController < BaseController
    REQUIRED_PARAMS = %w(resource_type capture_interval start_date).freeze

    # Default intervals in days
    HOURLY_INTERVAL = 31 # ~ 1 Month
    DAILY_INTERVAL = 730 # 2 Years

    def index
      validate_params

      start_date = params[:start_date].to_date
      end_date = params[:end_date].nil? ? start_date + default_interval : params[:end_date].to_date
      validate_dates(start_date, end_date)

      resources = MetricRollup.rollups_in_range(params[:resource_type], params[:resource_ids], params[:capture_interval], start_date, end_date)
      counts = Api::QueryCounts.new(MetricRollup.count, resources.count)

      render_collection(:metric_rollups, resources, :counts => counts, :expand_resources => @req.expand?(:resources))
    end

    private

    def default_interval
      @default_interval ||= self.class.const_get("#{params[:capture_interval].upcase}_INTERVAL")
    end

    def validate_params
      REQUIRED_PARAMS.each do |key|
        raise BadRequestError, "Must specify #{REQUIRED_PARAMS.join(', ')}" unless params[key.to_sym]
      end

      unless MetricRollup::CAPTURE_INTERVAL_NAMES.include?(params[:capture_interval])
        raise BadRequestError, "Capture interval must be one of #{MetricRollup::CAPTURE_INTERVAL_NAMES.join(', ')}"
      end
    end

    def validate_dates(start_date, end_date)
      # calculate interval in days
      interval = (end_date - start_date).to_i
      if interval > default_interval
        raise BadRequestError, "Cannot return #{params[:capture_interval]} rollups for an interval longer than #{default_interval} days"
      end
    end
  end
end
