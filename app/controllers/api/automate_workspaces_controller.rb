module Api
  class AutomateWorkspacesController < BaseController
    def edit_resource(type, id, data = {})
      obj = resource_search(id, type, collection_class(type))
      obj.merge_output!(data)
    end
  end
end
