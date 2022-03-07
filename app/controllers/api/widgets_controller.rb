module Api
  class WidgetsController < BaseController
    def generate_content_resource(type, id, _data = nil)
      api_resource(type, id, "Generating Content for") do |widget|
        widget.queue_generate_content
        {}
      end
    end
  end
end
