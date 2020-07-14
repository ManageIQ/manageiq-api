module Api
  module Subcollections
    module ConfiguredSystems
      def configured_systems_query_resource(object)
        object.respond_to?(:configured_systems) ? object.configured_systems : []
      end
    end
  end
end
