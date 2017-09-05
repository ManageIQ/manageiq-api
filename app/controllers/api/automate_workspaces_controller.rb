module Api
  class AutomateWorkspacesController < BaseController
    def index
      klass = collection_class(@req.subject)
      res, subquery_count = collection_search(@req.subcollection?, @req.subject, klass)
      opts = {
        :name             => @req.subject,
        :is_subcollection => @req.subcollection?,
        :expand_actions   => true,
        :expand_resources => @req.expand?(:resources),
        :counts           => Api::QueryCounts.new(klass.count, res.count, subquery_count)
      }
      render_collection(:automate_workspaces, res, opts)
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
      obj.merge_output!(data)
    end
  end
end
