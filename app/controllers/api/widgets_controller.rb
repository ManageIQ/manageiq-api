module Api
  class WidgetsController < BaseController
    def generate_content_resource(type, id, _data = nil)
      api_resource(type, id, "Generating Content for") do |widget|
        task_id = widget.queue_generate_content
        task_id ? {:task_id => task_id} : {}
      end
    end
  end
end
