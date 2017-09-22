module Api
  class MetricRollupsController < BaseController
    def index
      params[:offset] ||= 0
      params[:limit] ||= Settings.api.large_collection_default_limit

      rollups_service = MetricRollupsService.new(params)
      resources = rollups_service.query_metric_rollups
      res = collection_filterer(resources, :metric_rollups, MetricRollup).flatten
      counts = Api::QueryCounts.new(MetricRollup.count, res.count, resources.count)

      render_collection(:metric_rollups, res, :counts => counts, :expand_resources => @req.expand?(:resources))
    end
  end
end
