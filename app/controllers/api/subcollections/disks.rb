module Api
  module Subcollections
    module Disks
      def disks_query_resource(object)
        @additional_attributes = %w(partitions_aligned)
        object.disks
      end
    end
  end
end
