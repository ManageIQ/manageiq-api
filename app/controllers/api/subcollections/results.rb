module Api
  module Subcollections
    module Results
      include Api::Mixins::ReportResultSet

      def resource_id
        @req.subcollection_id
      end

      def find_results(id)
        MiqReportResult.for_user(User.current_user).find(id)
      end

      def results_query_resource(object)
        object.miq_report_results.for_user(User.current_user)
      end
    end
  end
end
