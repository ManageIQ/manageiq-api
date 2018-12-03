module Api
  module Subcollections
    module Results
      def initialize()
        @results_controller = Api::ResultsController.new
      end

      def find_results(id)
        MiqReportResult.for_user(User.current_user).find(id)
      end

      def results_query_resource(object)
        object.miq_report_results.for_user(User.current_user)
      end

      private

      def fetch_direct_virtual_attribute(type, resource, attr)
        @results_controller.fetch_direct_virtual_attribute(type, resource, attr)
      end
    end
  end
end
