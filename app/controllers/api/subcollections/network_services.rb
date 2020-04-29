module Api
  module Subcollections
    module NetworkServices
      def network_services_query_resource(object)
        object.respond_to?(:network_services) ? object.network_services : {}
      end
    end
  end
end
