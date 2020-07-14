module Api
  module Subcollections
    module ConfigurationProfiles
      def configuration_profiles_query_resource(object)
        object.respond_to?(:configuration_profiles) ? object.configuration_profiles : []
      end
    end
  end
end
