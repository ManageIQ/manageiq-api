module Api
  module Subcollections
    module ConfigurationProfiles
      def configuration_profiles_query_resource(object)
        if object.respond_to?(:configuration_profiles)
          object.configuration_profiles
        else
          raise ActiveRecord::RecordNotFound, "configuration_profiles not applicable"
        end
      end
    end
  end
end
