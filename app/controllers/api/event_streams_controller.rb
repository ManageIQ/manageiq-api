module Api
  class EventStreamsController < BaseController
    before_action :validate_filters, :ensure_pagination, :only => :index

    private

    def validate_filters
      messages = []
      messages << "must specify target_type" unless filter_contains?("target_type")
      messages << "must specify a minimum value for timestamp" unless filter_contains?("timestamp>")
      raise BadRequestError, messages.join(", ").capitalize if messages.any?
    end

    def filter_contains?(filter)
      Array(params["filter"]).any? { |f| f.start_with?(filter) }
    end

    def ensure_pagination
      params["limit"] ||= Settings.api.event_streams_default_limit
      params["offset"] ||= 0
    end
  end
end
