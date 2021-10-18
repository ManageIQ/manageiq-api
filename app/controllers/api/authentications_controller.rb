module Api
  class AuthenticationsController < BaseController
    def edit_resource(type, id, data)
      auth = resource_search(id, type, collection_class(:authentications))
      raise "Update not supported for #{authentication_ident(auth)}" unless auth.respond_to?(:update_in_provider_queue)
      task_id = auth.update_in_provider_queue(data.deep_symbolize_keys)
      action_result(true, "Updating #{authentication_ident(auth)}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def create_resource(_type, _id, data)
      manager_resource, attrs = validate_auth_attrs(data)
      task_id = AuthenticationService.create_authentication_task(manager_resource, attrs)
      action_result(true, 'Creating Authentication', :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource_main_action(type, auth, _data)
      ensure_respond_to(type, auth, :delete, :delete_in_provider_queue)
      {:task_id => auth.delete_in_provider_queue}
    end

    def refresh_resource(type, id, _data)
      auth = resource_search(id, type, collection_class(type))
      task_ids = EmsRefresh.queue_refresh_task(auth)
      action_result(true, "Refreshing #{authentication_ident(auth)}", :task_ids => task_ids)
    rescue => err
      action_result(false, err.to_s)
    end

    def options
      render_options(:authentications, build_additional_fields)
    end

    private

    def authentication_ident(auth)
      "Authentication id:#{auth.id} name: '#{auth.name}'"
    end

    def build_additional_fields
      {
        :credential_types => ::Authentication.build_credential_options
      }
    end

    def validate_auth_attrs(data)
      raise 'must supply a manager resource' unless data['manager_resource']
      attrs = data.dup.except('manager_resource')
      href = Href.new(data['manager_resource']['href'])
      raise 'invalid manager_resource href specified' unless href.subject && href.subject_id
      manager_resource = resource_search(href.subject_id, href.subject, collection_class(href.subject))
      [manager_resource, attrs]
    end
  end
end
