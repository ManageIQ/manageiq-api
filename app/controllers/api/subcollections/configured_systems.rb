module Api
  module Subcollections
    module ConfiguredSystems
      def configured_systems_query_resource(object)
        if object.respond_to?(:configured_systems)
          object.configured_systems
        else
          raise ActiveRecord::RecordNotFound, "configured_systems not applicable"
        end
      end
    end
  end
end
