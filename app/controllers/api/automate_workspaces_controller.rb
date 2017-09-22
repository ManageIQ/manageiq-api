module Api
  class AutomateWorkspacesController < BaseController
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
      obj.merge_output!(data)
    end
  end
end
