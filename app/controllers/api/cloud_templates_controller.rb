module Api
  class CloudTemplatesController < BaseController
    def check_compliance_resource(type, id, _data = nil)
      api_action(type, id) do |klass|
        cloud_template = resource_search(id, type, klass)
        api_log_info("Checking compliance of #{cloud_template_ident(cloud_template)}")
        request_compliance_check(cloud_template)
      end
    end

    private

    def cloud_template_ident(cloud_template)
      "CloudTemplate id:#{cloud_template.id} name:'#{cloud_template.name}'"
    end


    def request_compliance_check(cloud_template)
      desc = "#{cloud_template_ident(cloud_template)} check compliance requested"
      raise "#{cloud_template_ident(cloud_template)} has no compliance policies assigned" unless cloud_template.has_compliance_policies?

      task_id = queue_object_action(cloud_template, desc, :method_name => "check_compliance")
      action_result(true, desc, :task_id => task_id)
    rescue StandardError => err
      action_result(false, err.to_s)
    end
  end
end
