module Api
  module Subcollections
    module Schedules
      def schedules_query_resource(object)
        object.miq_schedules
      end

      def schedules_delete_resource(_parent, type, id, data)
        delete_resource(type, id, data)
      end
      alias delete_resource_schedules schedules_delete_resource
    end
  end
end
