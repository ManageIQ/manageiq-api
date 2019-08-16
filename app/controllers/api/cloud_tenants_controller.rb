module Api
  class CloudTenantsController < BaseController
    include Subcollections::SecurityGroups
    include Subcollections::Tags
  end
end
