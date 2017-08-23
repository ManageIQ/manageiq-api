module Api
  module Subcollections
    module MetricRollups
      RESOURCE_TYPES = {
        'vms' => 'VmOrTemplate'
      }.freeze

      def metric_rollups_query_resource(object)
        params[:resource_type] = RESOURCE_TYPES[@req.collection] || object.class.to_s
        params[:resource_ids] ||= [object.id]

        MetricRollupsService.query_metric_rollups(params)
      end
    end
  end
end
