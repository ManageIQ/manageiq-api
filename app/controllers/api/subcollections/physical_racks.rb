module Api
  module Subcollections
    module PhysicalRacks
      def physical_racks_query_resource(object)
        object.respond_to?(:physical_rack) ? PhysicalRack.where(:id => object.physical_rack_id) : []
      end
    end
  end
end
