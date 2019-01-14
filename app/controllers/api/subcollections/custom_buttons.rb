module Api
  module Subcollections
    module CustomButtons
      def custom_buttons_query_resource(object)
        object.custom_buttons
      end

      def custom_buttons_delete_resource(_object, type, id, data)
        delete_resource(type, id, data)
      end
    end
  end
end
