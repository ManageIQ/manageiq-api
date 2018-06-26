module Api
  module Mixins
    module ServiceTemplates
      def order_service_template(id, data, scheduled_time = nil)
        service_template = resource_search(id, :service_templates, ServiceTemplate)
        raise BadRequestError, "#{service_template_ident(service_template)} cannot be ordered" unless service_template.orderable?
        request_result = service_template.order(User.current_user, (data || {}), {:submit_workflow => true}, scheduled_time)
        errors = request_result[:errors]
        if errors.present?
          raise BadRequestError, "Failed to order #{service_template_ident(service_template)} - #{errors.join(", ")}"
        end
        request_result[:request] || request_result[:schedule]
      end

      private

      def service_template_ident(st)
        "Service Template id:#{st.id} name:'#{st.name}'"
      end
    end
  end
end
