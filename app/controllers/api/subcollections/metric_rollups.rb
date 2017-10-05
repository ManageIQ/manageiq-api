module Api
  module Subcollections
    module MetricRollups
      RESOURCE_TYPES = {
        'vms' => 'VmOrTemplate'
      }.freeze

      def metric_rollups_query_resource(object)
        params[:offset] ||= 0
        params[:limit] ||= Settings.api.max_results_per_page
        params[:resource_type] = RESOURCE_TYPES[@req.collection] || object.class.to_s
        params[:resource_ids] ||= [object.id]

        rollups_service = MetricRollupsService.new(params)
        rollups_service.query_metric_rollups
      end
    end
  end
end
