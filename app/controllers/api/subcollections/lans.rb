module Api
  module Subcollections
    module Lans
      def lans_query_resource(object)
        object.respond_to?(:lans) ? object.lans : []
      end
    end
  end
end
