module Api
  module Subcollections
    module RequestLogs
      def request_logs_query_resource(object)
        # object is the parent MiqRequest (or subclass), already RBAC-filtered by
        # parent_resource_obj before this method is called, so no additional check is needed.
        klass = collection_class(:request_logs)
        object ? klass.where(:resource_id => object.id) : {}
      end
    end
  end
end
