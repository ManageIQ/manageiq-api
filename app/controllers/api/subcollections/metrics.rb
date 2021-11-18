module Api
  module Subcollections
    module Metrics
      RESOURCE_TYPES = {
        'vms' => 'VmOrTemplate'
      }.freeze

      def metrics_query_resource(object)
        params[:resource_type] = RESOURCE_TYPES[@req.collection] || object.class.to_s
        params[:resource_ids] ||= [object.id]

        metrics_service = MetricsService.new(params)
        metrics_service.query_metrics
      end
    end
  end
end
