module Api
  class PolicyActionsController < BaseController
    def fetch_policy_actions_href_slug(resource)
      "policy_actions/#{resource.id}"
    end
  end
end
