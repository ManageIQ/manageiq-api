module Api
  module Subcollections
    module Results
      include Api::Mixins::ReportResultSet

      def resource_id
        @req.subcollection_id
      end

      def find_results(id)
        report_id = @req.collection_id
        MiqReport.find(report_id)
        MiqReportResult.with_report(report_id).for_user(User.current_user).find(id)
      end

      def results_query_resource(object)
        object.miq_report_results.for_user(User.current_user)
      end

      def results_delete_resource(_parent, type, miq_result_id, data)
        delete_resource(type, miq_result_id, data)
      end
      alias delete_resource_results results_delete_resource
    end
  end
end
