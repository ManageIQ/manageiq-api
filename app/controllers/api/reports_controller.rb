module Api
  class ReportsController < BaseController
    SCHEDULE_ATTRS_TO_TRANSFORM = %w(start_date interval time_zone send_email).freeze

    include Subcollections::Results

    before_action :set_additional_attributes, :only => [:index, :show]

    def reports_search_conditions
      MiqReport.for_user(User.current_user).where_clause.ast unless User.current_user.report_admin_user?
    end

    def find_reports(id)
      MiqReport.for_user(User.current_user).find(id)
    end

    def run_resource(type, id, _data)
      api_resource(type, id, "Running") do |report|
        report_result = MiqReportResult.find(report.queue_generate_table(:userid => User.current_userid))
        run_report_result(true,
                          "running report #{report.id}",
                          :task_id          => report_result.miq_task_id,
                          :report_result_id => report_result.id)
      rescue => err
        run_report_result(false, err.to_s)
      end
    end

    def run_report_result(success, message = nil, options = {})
      res = {:success => success}
      res[:message] = message if message.present?
      add_parent_href_to_result(res)
      add_report_result_to_result(res, options[:report_result_id]) if options[:report_result_id].present?
      add_task_to_result(res, options[:task_id]) if options[:task_id].present?
      res
    end

    def import_resource(_type, _id, data)
      options = data.fetch("options", {}).symbolize_keys.merge(:user => User.current_user)
      result, meta = MiqReport.import_from_hash(data["report"], options)
      action_result(meta[:level] == :info, meta[:message], :result => result)
    end

    def schedule_resource(type, id, data)
      api_resource(type, id, "Scheduling") do |report|
        schedule = report.add_schedule(fetch_schedule_data(data))
        res = action_result(true, "Scheduling #{model_ident(report, type)}")
        add_report_schedule_to_result(res, schedule.id, report.id)
      end
    end

    def schedules_query_resource(object)
      object ? object.list_schedules : {}
    end

    private

    def set_additional_attributes
      if @req.subcollection == "results" && (@req.subcollection_id || @req.expand?(:resources)) && attribute_selection == "all"
        @additional_attributes = %w(result_set)
      end
    end

    def fetch_schedule_data(data)
      schedule_data = data.except(*SCHEDULE_ATTRS_TO_TRANSFORM)

      schedule_data['userid'] = User.current_user.userid
      schedule_data['run_at'] = {
        :start_time => data['start_date'],
        :tz         => data['time_zone'],
        :interval   => {:unit  => data['interval']['unit'],
                        :value => data['interval']['value']}
      }

      # FIXME: the ReportController#show_saved route doesn't exist, it has to be reimplemented
      # for more information see https://github.com/ManageIQ/manageiq-ui-classic/issues/7126
      # email_url_prefix = url_for_only_path(:controller => "report", :action => "show_saved") + "/"
      email_url_prefix = "/report/show_saved/"

      schedule_options = {
        :send_email       => data['send_email'] || false,
        :email_url_prefix => email_url_prefix,
        :miq_group_id     => User.current_user.current_group_id
      }
      schedule_data['sched_action'] = {:method  => "run_report",
                                       :options => schedule_options}
      schedule_data
    end
  end
end
