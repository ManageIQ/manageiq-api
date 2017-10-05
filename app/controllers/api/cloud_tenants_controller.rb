module Api
  class CloudTenantsController < BaseController
    include Subcollections::SecurityGroups
  end
end
