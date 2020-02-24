module Api
  class PolicyProfilesController < BaseController
    include Subcollections::Policies

    def edit_resource(type, id, _data = {})
      raise ForbiddenError if collection_class(:policy_profiles).find(id).read_only?

      super
    end

    def delete_resource(type, id, _data = {})
      raise ForbiddenError if collection_class(:policy_profiles).find(id).read_only?

      super
    end
  end
end
