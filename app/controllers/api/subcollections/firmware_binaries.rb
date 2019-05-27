module Api
  module Subcollections
    module FirmwareBinaries
      def firmware_binaries_query_resource(object)
        object.compatible_firmware_binaries
      end
    end
  end
end
