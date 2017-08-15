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
      res = {}
      res["id"] = obj.id
      res["guid"] = obj.guid
      res["input"] = JSON.parse(obj.input)
      res["output"] = JSON.parse(obj.output) if obj.output
      
      render_resource :automate_workspaces, res
    end

    def edit_resource(type, id, data = {})
      klass = collection_class(type)
      obj = AutomateWorkspace.find_by(:guid => id)
      if obj.nil?
        raise NotFoundError, "Invalid Workspace #{id} specified"
      end
      workspace = data["workspace"]
      state_var = data["state_var"]
      if workspace.blank? && state_var.blank?
        raise BadRequestError, "No workspace or state_var specified for edit"
      end
      current_output = obj.output ? JSON.parse(obj.output) : {}
      obj.output = current_output.deep_merge(data).to_json
      obj.save
      obj
    end
  end
end
