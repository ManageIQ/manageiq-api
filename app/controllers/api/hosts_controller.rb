module Api
  class HostsController < BaseProviderController
    AUTH_ATTR = "authentications".freeze
    AUTH_TYPE_ATTR = "auth_type".freeze
    DEFAULT_AUTH_TYPE = "default".freeze

    include Subcollections::CustomAttributes
    include Subcollections::Lans
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags

    def edit_resource(type, id, data = {})
      authentications = data.delete(AUTH_ATTR)

      raise BadRequestError, "Cannot update non-credentials attributes of host resource" if data.any?

      resource_search(id, type).tap do |host|
        if authentications.present?
          authentications.deep_symbolize_keys!
          host.update_authentication(authentications)
        end
      end
    end

    def verify_credentials_resource(type, id = nil, data = {})
      api_resource(type, id, "Verifying Credentials for") do |host|
        auth_type = data["authentications"].keys.first

        {:task_id => host.verify_credentials_task(User.current_userid, auth_type, data)}
      end
    end

    def check_compliance_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Check Compliance for", :method_name => "check_compliance", :supports => true)
    end
  end
end
