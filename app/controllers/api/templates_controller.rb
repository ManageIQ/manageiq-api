module Api
  class TemplatesController < BaseController
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags

    def edit_resource(type, id = nil, data = {})
      super(type, id, data.extract!('name', 'description'))
    end

    def check_compliance_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Check Compliance for", :method_name => "check_compliance", :supports => true)
    end
  end
end
