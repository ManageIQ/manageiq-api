module Api
  module Mixins
    module ReportResultSet
      include Api::BaseController::Parameters::ResultsController

      def result_set
        ensure_pagination

        report_result = MiqReportResult.for_user(User.current_user).find(resource_id)
        result = report_result.result_set_for_reporting(report_options)

        hash = {:result_set => result[:result_set],
                :count      => result[:count_of_full_result_set],
                :subcount   => result[:result_set].count,
                :pages      => (result[:count_of_full_result_set] / params['limit'].to_f).ceil}

        report_result.attributes.merge(hash)
      end

      def show
        param_result_set? ? render_resource(:results, result_set) : super
      end
    end
  end
end
