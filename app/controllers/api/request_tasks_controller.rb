module Api
  class RequestTasksController < BaseController
    include Api::Mixins::ResourceCancel

    # execute queues the work.
    # this is typically called from within the workflow
    def execute_resource(type, id, _data)
      api_resource(type, id, "Executing") do |task|
        task.execute_queue
      end
    end

    # for a workflow/automate task, this kicks off the workflow
    #     that workflow will call execute directly
    # for other types of request tasks, this queues deliver
    def deliver_resource(type, id, _data)
      api_resource(type, id, "Delivering") do |task|
        task.deliver_queue
      end
    end
  end
end
