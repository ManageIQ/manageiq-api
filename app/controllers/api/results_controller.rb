module Api
  class ResultsController < BaseController
    before_action :set_additional_attributes, :only => [:index, :show]

    def results_search_conditions
      MiqReportResult.for_user(User.current_user).where_clause.ast
    end

    def sort_order
      params['sort_order'] == 'desc' ? :descending : :ascending
    end

    def param_result_set?
      params.key?(:hash_attribute) && params[:hash_attribute] == "result_set"
    end

    def report_options
      params.merge(:sort_by => params['sort_by'], :sort_order => sort_order).merge(filter_options)
    end

    def filter_options
      filtering_enabled? ? {:filter_string => params[:filter_string], :filter_column => params[:filter_column]} : {}
    end

    def filtering_enabled?
      params.key?(:filter_column) && params.key?(:filter_string) && params[:filter_string]
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
