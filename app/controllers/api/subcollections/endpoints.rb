module Api
  module Subcollections
    module Endpoints
      def endpoints_query_resource(object)
        return [] unless object.respond_to?(:endpoints)
        object.endpoints
      end

      def endpoints_add_resource(object, data = nil)
        data.each do |endpoint|
          object.endpoints << Endpoint.create!(endpoint)
        end
      rescue => err
        raise BadRequestError, "Endpoint - #{err}"
      end
    end
  end
end
