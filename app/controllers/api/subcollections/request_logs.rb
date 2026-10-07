module Api
  module Subcollections
    module RequestLogs
      def request_logs_query_resource(object)
        klass = collection_class(:request_logs)
        object ? klass.where(:resource_id => object.id) : {}
      end
    end
  end
end
