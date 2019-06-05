module Api
  module Subcollections
    module Cdroms
      def cdroms_query_resource(object)
        object.hardware.cdroms
      end
    end
  end
end
