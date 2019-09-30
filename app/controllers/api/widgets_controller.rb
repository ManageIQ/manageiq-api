module Api
  class WidgetsController < BaseController
    def generate_content_resource(type, id, _data = nil)
      api_action(type, id) do |klass|
        widget = resource_search(id, type, klass)
        api_log_info("Generating content for #{widget_ident(widget)}")
        generate_widget_content(widget)
      end
    end

    private

    def generate_widget_content(widget)
      desc = "#{widget_ident(widget)} content generation"
      task_id = queue_object_action(widget, desc, :method_name => "generate_content", :args => ["User", User.current_user.current_group.description, [User.current_user.userid]])
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def widget_ident(widget)
      "Widget id:#{widget.id} name:'#{widget.name}'"
    end
  end
end
