module Api
  module Subcollections
    module CloudSubnets
      def cloud_subnets_query_resource(object)
        object.respond_to?(:cloud_subnets) ? Array(object.cloud_subnets) : []
      end
    end
  end
end
