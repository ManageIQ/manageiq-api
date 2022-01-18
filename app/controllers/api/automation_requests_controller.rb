module Api
  class AutomationRequestsController < BaseController
    include Api::Mixins::ResourceCancel
    include Api::Mixins::ResourceApproveDeny
    include Subcollections::RequestTasks

    def create_resource(type, _id, data)
      assert_id_not_specified(data, type)

      version_str = data["version"] || "1.1"
      uri_parts   = hash_fetch(data, "uri_parts")
      parameters  = hash_fetch(data, "parameters")
      requester   = hash_fetch(data, "requester")

      AutomationRequest.create_from_ws(version_str, User.current_user, uri_parts, parameters, requester)
    end

    def edit_resource(type, id, data)
      request = resource_search(id, type)
      RequestEditor.edit(request, data)
      request
    end

    def find_automation_requests(id)
      klass = collection_class(:requests)
      return klass.find(id) if User.current_user.miq_user_role.request_admin_user?
      klass.find_by!(:requester => User.current_user, :id => id)
    end

    def automation_requests_search_conditions
      return {} if User.current_user.miq_user_role.request_admin_user?
      {:requester => User.current_user}
    end
  end
end
