module Api
  class ResourcePoolInfrasController < BaseController
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags
  end
end
