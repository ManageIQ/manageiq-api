module Api
  class EventStreamsController < BaseController
    before_action :ensure_pagination, :only => :index

    private

    def ensure_pagination
      params["limit"] ||= Settings.api.event_streams_default_limit
      params["offset"] ||= 0
    end
  end
end
