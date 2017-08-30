module Api
  class AutomateWorkspacesController < BaseController
    def index
      raise BadRequestError, "Fetches of collection is not allowed"
    end

    def show
      obj = AutomateWorkspace.find_by(:guid => @req.c_id)
      if obj.nil?
        raise NotFoundError, "Invalid Workspace #{@req.c_id} specified"
      end

      render_resource(:automate_workspaces, obj)
    end

    def edit_resource(_type, id, data = {})
      obj = AutomateWorkspace.find_by(:guid => id)
      if obj.nil?
        raise NotFoundError, "Invalid Workspace #{id} specified"
      end
      obj.output = data
    end
  end
end
