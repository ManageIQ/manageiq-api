module Api
  class ResultsController < BaseController
    include Api::Mixins::ReportResultSet
    include Api::Mixins::ResultDownloads

    before_action :set_additional_attributes, :only => [:index, :show]

    def resource_id
      @req.collection_id
    end

    def results_search_conditions
      MiqReportResult.for_user(User.current_user).where_clause.ast
    end

    def find_results(id)
      MiqReportResult.for_user(User.current_user).find(id)
    end

    def request_download_resource(_type, id, data)
      result      = find_results(id)
      result_type = validate_result_type(data["result_type"])
      desc        = "Requesting a download of a #{result_type} report for #{result_ident(result)}"
      session_id  = "#{request.uuid}-#{SecureRandom.hex(4)}" # Adding a random hex suffix for bulk requests

      task_id = if result_type == "pdf"
                  task = MiqTask.new(:name              => "Generate Report result [#{result_type}]: '#{result.report.name}'",
                                     :miq_report_result => result,
                                     :userid            => User.current_user.userid)
                  task.update_status("Finished", "Ok", "Complete")
                  task.id
                else
                  result.async_generate_result(result_type, :userid => User.current_user.userid, :session_id => session_id)
                end
      MiqTask.find(task_id).update_context(:result_id => result.id, :result_type => result_type, :session_id => session_id)

      action_result(true, desc, :task_id => task_id, :task_results => task_id)
    rescue StandardError => err
      action_result(false, err.to_s)
    end

    private

    def result_ident(result)
      "Result id:#{result.id} name:'#{result.name}'"
    end

    def set_additional_attributes
      @additional_attributes = %w(result_set)
    end
  end
end
