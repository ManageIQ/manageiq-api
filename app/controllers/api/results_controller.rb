module Api
  class ResultsController < BaseController
    include Parameters::ResultsController

    before_action :set_additional_attributes, :only => [:index, :show]

    def results_search_conditions
      MiqReportResult.for_user(User.current_user).where_clause.ast
    end

    def result_set
      ensure_pagination

      report_result = MiqReportResult.for_user(User.current_user).find(@req.collection_id)
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

    def find_results(id)
      MiqReportResult.for_user(User.current_user).find(id)
    end

    private

    def set_additional_attributes
      @additional_attributes = %w(result_set)
    end
  end
end
