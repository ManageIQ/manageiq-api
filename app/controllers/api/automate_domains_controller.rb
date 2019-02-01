module Api
  class AutomateDomainsController < BaseController
    def delete_resource(type, id = nil, _data = {})
      raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless id

      delete_resource_action(type, id)
    end

    def refresh_from_source_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for refreshing a #{type} resource from source" unless id

      api_action(type, id) do |klass|
        domain = resource_search(id, type, klass)
        api_log_info("Refreshing #{automate_domain_ident(domain)}")

        begin
          unless GitBasedDomainImportService.available?
            raise "Git owner role is not enabled to be able to import git repositories"
          end
          raise "#{automate_domain_ident(domain)} did not originate from git repository" unless domain.git_repository
          ref = data["ref"] || domain.ref
          ref_type = data["ref_type"] || domain.ref_type

          description = "Refreshing #{automate_domain_ident(domain)} from git repository"
          task_id = GitBasedDomainImportService.new.queue_refresh_and_import(domain.git_repository.url,
                                                                             ref,
                                                                             ref_type,
                                                                             current_tenant.id)
          action_result(true, description, :task_id => task_id)
        rescue => err
          action_result(false, err.to_s)
        end
      end
    end

    private

    def delete_resource_action(type, id)
      api_action(type, id) do |klass|
        domain = resource_search(id, type, klass)
        api_log_info("Delete will be queued for #{automate_domain_ident(domain)}")

        begin
          # Only delete unlocked user domains. System or GIT based domains will not be deleted.
          MiqAeDomain.where(:name => domain.name).each { |d| raise "Not deleting. Domain is locked." if d.contents_locked? }

          MiqAeDomain.where(:name => domain.name).each(&:destroy_queue)
          action_result(true, "Delete queued for #{automate_domain_ident(domain)}")
        rescue => err
          action_result(false, err.to_s)
        end
      end
    end

    def automate_domain_ident(domain)
      "Automate Domain id:#{domain.id} name:'#{domain.name}'"
    end

    def resource_search(id, type, klass)
      if id.to_s =~ /\A\d+\z/
        super
      else
        begin
          domain = collection_class(:automate_domains).find_by!(:name => id)
        rescue
          raise NotFoundError, "Couldn't find #{klass} with 'name'=#{id}"
        end
        super(domain.id, type, klass)
      end
    end

    def current_tenant
      User.current_user.current_tenant || Tenant.default_tenant
    end
  end
end
