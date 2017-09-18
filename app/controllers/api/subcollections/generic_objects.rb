module Api
  module Subcollections
    module GenericObjects
      def generic_objects_query_resource(object_definition)
        object_definition.generic_objects
      end

      def generic_objects_create_resource(object, _type, _id, data)
        create_generic_object(object, data)
      end
    end
  end
end
