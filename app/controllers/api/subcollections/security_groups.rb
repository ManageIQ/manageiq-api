module Api
  module Subcollections
    module SecurityGroups
      def security_groups_query_resource(object)
        object.respond_to?(:security_groups) ? object.security_groups : []
      end
    end
  end
end
