module Api
  module Mixins
    module ServiceTemplates
      def order_service_template(id, data)
        service_template = resource_search(id, :service_templates, ServiceTemplate)
        raise BadRequestError, "#{service_template_ident(service_template)} cannot be ordered" unless service_template.orderable?
        workflow = service_template.provision_workflow(User.current_user, data || {}, :submit_workflow => true)
        request_result = workflow.submit_request
        errors = request_result[:errors]
        if errors.present?
          raise BadRequestError, "Failed to order #{service_template_ident(service_template)} - #{errors.join(", ")}"
        end
        request_result[:request]
      end

      private

      def service_template_ident(st)
        "Service Template id:#{st.id} name:'#{st.name}'"
      end
    end
  end
end
