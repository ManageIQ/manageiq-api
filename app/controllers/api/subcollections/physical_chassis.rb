module Api
  module Subcollections
    module PhysicalChassis
      def physical_chassis_query_resource(object)
        object.respond_to?(:physical_chassis) ? ManageIQ::Providers::PhysicalInfraManager::PhysicalChassis.where(:id => object.physical_chassis_id) : []
      end
    end
  end
end
