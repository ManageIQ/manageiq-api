module Api
  class EventStreamsController < BaseController
    def options
      render_options(@req.collection, build_additional_fields)
    end

    private

    def build_additional_fields
      {:timeline_events => EventStream.timeline_options}
    end
  end
end
