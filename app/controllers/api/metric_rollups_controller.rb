module Api
  class MetricRollupsController < BaseController
    def index
      resources = MetricRollupsService.query_metric_rollups(params)
      res = collection_filterer(resources, :metric_rollups, MetricRollup).flatten
      counts = Api::QueryCounts.new(MetricRollup.count, res.count, resources.count)

      render_collection(:metric_rollups, res, :counts => counts, :expand_resources => @req.expand?(:resources))
    end
  end
end
