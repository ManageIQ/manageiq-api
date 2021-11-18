module Api
  class MetricsController < BaseController
    def index
      metrics_service = MetricsService.new(params)

      resources = metrics_service.query_metrics
      res       = collection_filterer(resources, :metrics, Metric).flatten
      counts    = Api::QueryCounts.new(Metric.count, res.count, resources.count)

      render_collection(:metrics, res, :counts => counts, :expand_resources => @req.expand?(:resources))
    end
  end
end
