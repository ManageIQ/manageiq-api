module Api
  class TemplatesController < BaseController
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags

    def edit_resource(type, id = nil, data = {})
      super(type, id, data.extract!('name', 'description'))
    end

    def check_compliance_resource(type, id, _data = nil)
      api_action(type, id) do |klass|
        template = resource_search(id, type, klass)
        api_log_info("Checking compliance of #{template_ident(template)}")
        request_compliance_check(template)
      end
    end

    private

    def template_ident(template)
      "Template id:#{template.id} name:'#{template.name}'"
    end

    def request_compliance_check(template)
      desc = "#{template_ident(template)} check compliance requested"
      raise "#{template_ident(template)} has no compliance policies assigned" unless template.has_compliance_policies?

      task_id = queue_object_action(template, desc, :method_name => "check_compliance")
      action_result(true, desc, :task_id => task_id)
    rescue StandardError => err
      action_result(false, err.to_s)
    end
  end
end
