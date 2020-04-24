module Api
  class HostsController < BaseController
    CREDENTIALS_ATTR = "credentials".freeze
    AUTH_TYPE_ATTR = "auth_type".freeze
    DEFAULT_AUTH_TYPE = "default".freeze

    include Subcollections::CustomAttributes
    include Subcollections::Lans
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags

    def edit_resource(type, id, data = {})
      credentials = data.delete(CREDENTIALS_ATTR)
      raise BadRequestError, "Cannot update non-credentials attributes of host resource" if data.any?
      resource_search(id, type, collection_class(:hosts)).tap do |host|
        all_credentials = Array.wrap(credentials).each_with_object({}) do |creds, hash|
          auth_type = creds.delete(AUTH_TYPE_ATTR) || DEFAULT_AUTH_TYPE
          creds.symbolize_keys!
          creds.reverse_merge!(:userid => host.authentication_userid(auth_type))
          hash[auth_type.to_sym] = creds
        end
        host.update_authentication(all_credentials) if all_credentials.present?
      end
    end

    def check_compliance_resource(type, id, _data = nil)
      api_action(type, id) do |klass|
        host = resource_search(id, type, klass)
        api_log_info("Checking compliance of #{host_ident(host)}")
        request_compliance_check(host)
      end
    end

    private

    def host_ident(host)
      "Host id:#{host.id} name:'#{host.name}'"
    end

    def request_compliance_check(host)
      desc = "#{host_ident(host)} check compliance requested"
      raise "#{host_ident(host)} has no compliance policies assigned" if host.compliance_policies.blank?

      task_id = queue_object_action(host, desc, :method_name => "check_compliance")
      action_result(true, desc, :task_id => task_id)
    rescue StandardError => err
      action_result(false, err.to_s)
    end
  end
end
