module Api
  class ResourcePoolsController < BaseController
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags

    # GET /api/resource_pools
    def index
      if params[:type].present?
        resource_pools = fetch_resource_pools_by_type(params[:type])
        res = collection_filterer(resource_pools, :resource_pools, ResourcePool).flatten
        counts = Api::QueryCounts.new(ResourcePool.count, res.count, resource_pools.count)
        render_collection(:resource_pools, res, :counts => counts, :expand_resources => @req.expand?(:resources), :name => 'resource_pools')
      else
        super
      end
    end

    private

    # Fetch resource pools by exact type
    def fetch_resource_pools_by_type(type)
      rp = type.safe_constantize unless type.is_a?(Class)
      if rp && rp <= ResourcePool
        rp.all
      else
        ResourcePool.none
      end
    end
  end
end
