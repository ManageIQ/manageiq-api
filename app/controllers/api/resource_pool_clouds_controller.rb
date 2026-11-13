module Api
  class ResourcePoolCloudsController < BaseController
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags
  end
end
