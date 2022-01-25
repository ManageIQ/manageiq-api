module Api
  class TemplatesController < BaseController
    include Api::Mixins::Genealogy
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags

    def edit_resource(type, id, data)
      edit_resource_with_genealogy(type, id, data)
    rescue => err
      raise BadRequestError, "Cannot edit Template - #{err}"
    end

    def check_compliance_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Check Compliance for", :method_name => "check_compliance", :supports => true)
    end
  end
end
