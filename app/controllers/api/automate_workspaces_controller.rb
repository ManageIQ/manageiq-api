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
      workspace = data["workspace"]
      state_var = data["state_var"]
      if workspace.blank? && state_var.blank?
        raise BadRequestError, "No workspace or state_var specified for edit"
      end
      current_output = obj.output || {}
      obj.output = current_output.deep_merge(data)
      obj.save
      obj
    end
  end
end
