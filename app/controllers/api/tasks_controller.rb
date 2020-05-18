module Api
  class TasksController < BaseController
    include Api::Mixins::ResultDownloads

    def find_collection(klass)
      return klass.where(:userid => [current_user.userid]) if current_user.only_my_user_tasks?

      super
    end

    def find_resource(klass, key_id, id)
      return klass.find_by(key_id => id, :userid => [current_user.userid]) if current_user.only_my_user_tasks?

      super
    end

    def render_task_results_entity
      id = params[:c_id]
      task = find_resource(collection_class(:tasks), :id, id)
      raise "Missing context_data in #{task_ident(task)}" if task.context_data.blank?

      result_id = task.context_data[:result_id]
      raise "Missing result_id in #{task_ident(task)}" if result_id.blank?

      result_type = task.context_data[:result_type]
      raise "Missing result_type in #{task_ident(task)}" if result_type.blank?

      session_id = task.context_data[:session_id]
      raise "Missing session_id in #{task_ident(task)}" if session_id.blank?

      validate_result_type(result_type)
      task_results = result_type == "pdf" ? task.miq_report_result.to_pdf : task.task_results
      filename     = "results_#{result_id}_report.#{result_type}"
      content_type = RESULT_TYPE_TO_CONTENT_TYPE[result_type]
      send_data(task_results, :filename => filename, :disposition => "attachment", :content_type => content_type)
    rescue => err
      raise BadRequestError, err
    end

    private

    def task_ident(task)
      "Task id:#{task.id} name:'#{task.name}'"
    end
  end
end
