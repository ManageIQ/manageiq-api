module Api
  module Mixins
    module ServiceTemplates
      def order_service_template(id, data, scheduled_time = nil)
        service_template = resource_search(id, :service_templates, ServiceTemplate)
        raise BadRequestError, "#{service_template_ident(service_template)} cannot be ordered" unless orderable?(service_template)
        request_result = service_template.order(User.current_user, (data || {}), order_request_options, scheduled_time)
        errors = request_result[:errors]
        if errors.present?
          raise BadRequestError, "Failed to order #{service_template_ident(service_template)} - #{errors.join(", ")}"
        end
        request_result[:request] || request_result[:schedule]
      end

      private

      def orderable?(service_template)
        api_request_allowed? && service_template.orderable?
      end

      def api_request_allowed?
        return true if request_from_ui?
        Settings.product.allow_api_service_ordering
      end

      def request_from_ui?
        return false if request.headers["x-auth-token"].blank?
        token_info.present?
      end

      def order_request_options
        init_defaults = !request_from_ui? && Settings.product.run_automate_methods_on_service_api_submit

        {:submit_workflow => request_from_ui?, :init_defaults => init_defaults}
      end

      def token_info
        requester_type = params['requester_type'] || 'api'
        Environment.user_token_service.token_mgr(requester_type).token_get_info(request.headers["x-auth-token"])
      end

      def service_template_ident(st)
        "Service Template id:#{st.id} name:'#{st.name}'"
      end
    end
  end
end
