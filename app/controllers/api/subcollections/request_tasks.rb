module Api
  module Subcollections
    module RequestTasks
      def request_tasks_query_resource(object)
        klass = collection_class(:request_tasks)
        object ? klass.where(:miq_request_id => object.id) : {}
      end

      def request_tasks_edit_resource(_object, type, id = nil, data = {})
        raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id
        request_task = resource_search(id, type, collection_class(:request_tasks))
        request_task.update_request_task(data)
        request_task
      end
    end
  end
end
