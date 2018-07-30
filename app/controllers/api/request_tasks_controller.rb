module Api
  class RequestTasksController < BaseController
    include Api::Mixins::ResourceCancel
  end
end
