module Api
  module Subcollections
    module Networks
      def networks_query_resource(object)
        object.respond_to?(:networks) ? object.networks : []
      end
    end
  end
end
