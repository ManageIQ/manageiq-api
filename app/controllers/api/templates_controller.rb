module Api
  class TemplatesController < BaseController
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags

    def edit_resource(type, id = nil, data = {})
      super(type, id, data.extract!('name', 'description'))
    end
  end
end
