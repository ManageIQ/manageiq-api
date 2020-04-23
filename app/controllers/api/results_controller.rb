module Api
  class ResultsController < BaseController
    include Api::Mixins::ReportResultSet

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

    private

    def set_additional_attributes
      @additional_attributes = %w(result_set)
    end
  end
end
