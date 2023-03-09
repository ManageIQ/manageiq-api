module Api
  class HostsController < BaseController
    CREDENTIALS_ATTR = "credentials".freeze
    AUTH_ATTR = "authentications".freeze
    AUTH_TYPE_ATTR = "auth_type".freeze
    DEFAULT_AUTH_TYPE = "default".freeze

    include Subcollections::CustomAttributes
    include Subcollections::Lans
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags

    def edit_resource(type, id, data = {})
      # TODO: drop 'credentials' parameter field when ui-classic hosts is in react
      credentials = data.delete(CREDENTIALS_ATTR)
      authentications = data.delete(AUTH_ATTR)
      raise BadRequestError, "Cannot update non-credentials attributes of host resource" if data.any?
      resource_search(id, type).tap do |host|
        # begin legacy ui-classic
        all_credentials = Array.wrap(credentials).each_with_object({}) do |creds, hash|
          auth_type = creds.delete(AUTH_TYPE_ATTR) || DEFAULT_AUTH_TYPE
          creds.symbolize_keys!
          creds.reverse_merge!(:userid => host.authentication_userid(auth_type))
          hash[auth_type.to_sym] = creds
        end
        # end legacy ui-classic. if they provided the newer authentications, it will overwrite
        all_credentials, _ = symbolize_password_keys!(authentications) if authentications
        host.update_authentication(all_credentials) if all_credentials.present?
      end
    end

    def verify_credentials_resource(type, id = nil, data = {})
      api_resource(type, id, "Verifying Credentials for") do |host|
        remember_host = data["remember_host"] == "true"
        authentications, auth_type = symbolize_password_keys!(data[AUTH_ATTR])
        {:task_id => host.verify_credentials_task(User.current_userid, auth_type, :credentials => authentications, :remember_host => remember_host)}
      end
    end

    def check_compliance_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Check Compliance for", :method_name => "check_compliance", :supports => true)
    end

    private

    # takes credentials from params and converts into something for update_authentications
    def symbolize_password_keys!(authentications)
      auth_type = authentications.keys.first
      # symbolize userid, password
      authentications[auth_type].symbolize_keys!

      return authentications, auth_type
    end
  end
end
