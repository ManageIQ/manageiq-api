module Api
  class AutomateNamespacesController < BaseController
    def delete_resource(type, id = nil, _data = {})
      raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless id

      delete_resource_action(type, id)
    end
  end
end
