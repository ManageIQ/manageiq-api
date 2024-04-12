module Api
  module Subcollections
    module MetricRollups
      RESOURCE_TYPES = {
        'vms'       => 'VmOrTemplate',
        'providers' => 'ExtManagementSystem'
      }.freeze

      def metric_rollups_query_resource(object)
        params[:resource_type] = RESOURCE_TYPES[@req.collection] || object.class.to_s
        params[:resource_ids] ||= [object.id]

        rollups_service = MetricRollupsService.new(params)
        rollups_service.query_metric_rollups
      end
    end
  end
end
