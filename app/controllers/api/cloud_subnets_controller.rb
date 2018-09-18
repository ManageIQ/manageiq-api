module Api
  class CloudSubnetsController < BaseController
    include Subcollections::Tags
    include Subcollections::SecurityGroups
  end
end
