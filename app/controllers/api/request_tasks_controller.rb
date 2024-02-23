module Api
  class RequestTasksController < BaseController
    include Api::Mixins::ResourceCancel

    # execute queues the work.
    # this is typically called from within the workflow
    def execute_resource(type, id, _data)
      api_resource(type, id, "Executing") do |task|
        raise BadRequestError, "Resource must be approved. state is #{task.state}" unless task.approved?

        task.execute_queue
      end
    end
  end
end
