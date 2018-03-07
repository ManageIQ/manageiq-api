module Api
  module Subcollections
    module Folders
      def folders_query_resource(object)
        object.respond_to?(:folders) ? object.folders : []
      end
    end
  end
end
