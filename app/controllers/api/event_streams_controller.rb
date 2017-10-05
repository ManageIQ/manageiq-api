module Api
  class EventStreamsController < BaseController
    before_action :ensure_pagination, :only => :index

    private

    def ensure_pagination
      params["limit"] ||= Settings.api.max_results_per_page
      params["offset"] ||= 0
    end
  end
end
