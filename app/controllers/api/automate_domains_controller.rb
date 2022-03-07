module Api
  class AutomateDomainsController < BaseController
    REQUIRED_FIELDS = %w[git_url ref_type ref_name].freeze

    def create_from_git_resource(type, _id, data)
      assert_all_required_fields_exists(data, type, REQUIRED_FIELDS)
      raise BadRequestError, 'ref_type must be "branch" or "tag"' unless valid_ref_type?(data)

      api_log_info("Create will be queued for automate domain from #{data["git_url"]} / #{data["ref_name"]}")

      begin
        svc = domain_import_service
        task_id = svc.queue_refresh_and_import(data["git_url"],
                                               data["ref_name"],
                                               data["ref_type"],
                                               User.current_user.current_tenant.id,
                                               prepare_optional_auth(data))

        action_result(true, "Creating Automate Domain from #{data["git_url"]}/#{data["ref_name"]}", :task_id => task_id)
      rescue => err
        action_result(false, err.to_s)
      end
    end

    def refresh_from_source_resource(type, id = nil, data = nil)
      api_resource(type, id, "Refreshing") do |domain|
        svc = domain_import_service
        # TODO: introduce this logic into Domain#supports :refresh
        raise BadRequestError, "#{model_ident(domain, type)} did not originate from git repository" unless domain.git_repository

        task_id = svc.queue_refresh_and_import(domain.git_repository.url,
                                               data["ref"] || domain.ref,
                                               data["ref_type"] || domain.ref_type,
                                               current_tenant.id)
        action_result(true, "Refreshing #{model_ident(domain, type)} from git repository", :task_id => task_id)
      end
    end

    private

    def domain_import_service
      unless GitBasedDomainImportService.available?
        raise BadRequestError, "Git owner role is not enabled to be able to import git repositories"
      end

      GitBasedDomainImportService.new
    end

    def delete_resource_main_action(_type, domain, _data = {})
      # TODO: Research why we are looking up the domain again if we already have one
      # Only delete unlocked user domains. System or GIT based domains will not be deleted.
      domains = MiqAeDomain.where(:name => domain.name).to_a
      domains.each { |d| raise BadRequestError, "Not deleting. Domain is locked." if d.contents_locked? }
      domains.each(&:destroy_queue)
      {}
    end

    def resource_search(id, type, klass = nil, key_id = nil)
      key_id = "name" if id && !id.integer?
      super
    end

    def current_tenant
      User.current_user.current_tenant || Tenant.default_tenant
    end

    def valid_ref_type?(data = {})
      %w[tag branch].include?(data["ref_type"]) if data.key?("ref_type")
    end

    def prepare_optional_auth(data)
      optional_auth = {}
      optional_auth["userid"] = data["userid"] if data.key?("userid")
      optional_auth["password"] = data["password"] if data.key?("password")

      # If data["verify_ssl"] is missing or set to false use VERIFY_NONE. If true use VERIFY_PEER
      optional_auth["verify_ssl"] = data["verify_ssl"] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

      optional_auth
    end
  end
end
