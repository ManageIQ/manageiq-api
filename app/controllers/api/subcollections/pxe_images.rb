module Api
  module Subcollections
    module PxeImages
      def pxe_images_query_resource(object)
        object.images
      end
    end
  end
end
