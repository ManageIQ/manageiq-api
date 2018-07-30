module Api
  module Subcollections
    module Schedules
      def schedules_query_resource(object)
        object.miq_schedules
      end

      def schedules_delete_resource(_parent, type, id, data)
        delete_resource(type, id, data)
      end
      alias delete_resource_schedules schedules_delete_resource

      def schedules_edit_resource(_parent, _type, id, data)
        # We need to hit #edit_resource from the BaseController, not any of the override methods in child controllers
        BaseController.instance_method(:edit_resource).bind(self).call(:schedules, id, data.deep_symbolize_keys)
      rescue => err
        raise BadRequestError, "Could not update Schedule - #{err}"
      end
    end
  end
end
