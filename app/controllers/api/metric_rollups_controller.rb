module Api
  class MetricRollupsController < BaseController
    def index
      if params[:resource_type]
        resources = MetricRollup.latest_rollups(params[:resource_type], params[:resource_ids], params[:capture_interval])
        render_resource :metric_rollups, :count => MetricRollup.count, :subcount => resources.to_a.size, :resources => resources
      else
        super
      end
    end
  end
end
