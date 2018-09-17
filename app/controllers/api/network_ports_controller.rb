module Api
  class NetworkPortsController < BaseController
    include Subcollections::CloudSubnets
    include Subcollections::SecurityGroups
  end
end
