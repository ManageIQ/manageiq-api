module Api
  class AuthenticationsController < BaseController
    def edit_resource(type, id, data)
      resource_task_result(type, id, :update) do |auth|
        auth.update_in_provider_queue(data.deep_symbolize_keys)
      end
    end

    # very similar, but not quite right. probably need to extend create_resource_task_result
    def create_resource(_type, _id, data)
      attrs = data.dup.except('manager_resource')

      # href = manager_info(data)
      # create_resource_task_result(href.subject, href.subject_id) do |manager_resource|
      #   AuthenticationService.create_authentication_task(manager_resource, attrs)
      # end

      manager_resource = validate_auth_attrs(data)
      task_id = AuthenticationService.create_authentication_task(manager_resource, attrs)
      action_result(true, 'Creating Authentication', :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource(type, id, _data = {})
      resource_task_result(type, id, :update) do |auth|
        auth.update_in_provider_queue(data.deep_symbolize_keys)
      end
    end

    def refresh_resource(type, id, _data)
      resource_task_result(type, id, :refresh) do |auth|
        EmsRefresh.queue_refresh_task(auth)
      end
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

    def manager_info(data)
      raise BadRequestError, 'must supply a manager resource' unless data['manager_resource']
      href = Href.new(data['manager_resource']['href'])
      raise BadRequestError, 'invalid manager_resource href specified' unless href.subject && href.subject_id
      href
    end

    def validate_auth_attrs(data)
      href = manager_info(data)
      resource_search(href.subject_id, href.subject, collection_class(href.subject))
    end
  end
end
