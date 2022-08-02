module Api
  module Subcollections
    module CloudVolumeTypes
      def cloud_volume_types_query_resource(object)
        object.respond_to?(:cloud_volume_types) ? object.cloud_volume_types : []
      end
    end
  end
end
