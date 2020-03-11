module Api
  class ClustersController < BaseController
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags

    def options
      render_options(:clusters, :node_types => "mixed_clusters")
    end
  end
end
