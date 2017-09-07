RSpec.describe 'Configuration Script Sources API' do
  let(:provider) { FactoryGirl.create(:ext_management_system) }
  let(:config_script_src) { FactoryGirl.create(:ansible_configuration_script_source, :manager => provider) }
  let(:config_script_src_2) { FactoryGirl.create(:ansible_configuration_script_source, :manager => provider) }
  let(:ansible_provider)      { FactoryGirl.create(:provider_ansible_tower, :with_authentication) }
  let(:manager) { ansible_provider.managers.first }

  describe 'GET /api/configuration_script_sources' do
    it 'lists all the configuration script sources with an appropriate role' do
      repository = FactoryGirl.create(:configuration_script_source)
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :read, :get)

      run_get(api_configuration_script_sources_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'configuration_script_sources',
        'resources' => [hash_including('href' => api_configuration_script_source_url(nil, repository.compressed_id))]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to configuration script sources without an appropriate role' do
      api_basic_authorize

      run_get(api_configuration_script_sources_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/configuration_script_sources/:id' do
    it 'will show a configuration script source with an appropriate role' do
      repository = FactoryGirl.create(:configuration_script_source)
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :read, :get)

      run_get(api_configuration_script_source_url(nil, repository))

      expected = {
        'href' => api_configuration_script_source_url(nil, repository.compressed_id)
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to a configuration script source without an appropriate role' do
      repository = FactoryGirl.create(:configuration_script_source)
      api_basic_authorize

      run_get(api_configuration_script_source_url(nil, repository))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/configuration_script_sources' do
    let(:params) do
      {
        :id          => config_script_src.id,
        :name        => 'foo',
        :description => 'bar'
      }
    end

    it 'will bulk update configuration_script_sources with an appropriate role' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :edit, :post)
      params2 = params.dup.merge(:id => config_script_src_2.id)

      run_post(api_configuration_script_sources_url, :action => 'edit', :resources => [params, params2])

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Updating ConfigurationScriptSource'),
            'task_id' => a_kind_of(String)
          ),
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Updating ConfigurationScriptSource'),
            'task_id' => a_kind_of(String)
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids updating configuration_script_sources without an appropriate role' do
      api_basic_authorize

      run_post(api_configuration_script_sources_url, :action => 'edit', :resources => [params])

      expect(response).to have_http_status(:forbidden)
    end

    it 'will delete multiple configuration script source with an appropriate role' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :delete, :post)

      run_post(api_configuration_script_sources_url, :action => 'delete', :resources => [{:id => config_script_src.id}, {:id => config_script_src_2.id}])

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Deleting ConfigurationScriptSource'),
            'task_id' => a_kind_of(String)
          ),
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Deleting ConfigurationScriptSource'),
            'task_id' => a_kind_of(String)
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids delete without an appropriate role' do
      api_basic_authorize

      run_post(api_configuration_script_sources_url, :action => 'delete', :resources => [{:id => config_script_src.id}])

      expect(response).to have_http_status(:forbidden)
    end

    it 'can refresh multiple configuration_script_source with an appropriate role' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :refresh, :post)

      run_post(api_configuration_script_sources_url, :action => :refresh, :resources => [{ :id => config_script_src.id}, {:id => config_script_src_2.id}])

      expected = {
        'results' => [
          a_hash_including(
            'success'   => true,
            'message'   => a_string_including("Refreshing ConfigurationScriptSource id:#{config_script_src.id}"),
            'task_id'   => a_kind_of(String),
            'task_href' => /task/,
            'tasks'     => [a_hash_including('id' => a_kind_of(String), 'href' => /task/)]
          ),
          a_hash_including(
            'success'   => true,
            'message'   => a_string_including("Refreshing ConfigurationScriptSource id:#{config_script_src_2.id}"),
            'task_id'   => a_kind_of(String),
            'task_href' => /task/,
            'tasks'     => [a_hash_including('id' => a_kind_of(String), 'href' => /task/)]
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'PUT /api/configuration_script_sources/:id' do
    let(:params) do
      {
        :name        => 'foo',
        :description => 'bar'
      }
    end

    it 'updates a configuration_script_source with an appropriate role' do
      api_basic_authorize action_identifier(:configuration_script_sources, :edit)

      run_put(api_configuration_script_source_url(nil, config_script_src), :resource => params)

      expected = {
        'success' => true,
        'message' => a_string_including('Updating ConfigurationScriptSource'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'PATCH /api/configuration_script_sources/:id' do
    let(:params) do
      {
        :action      => 'edit',
        :name        => 'foo',
        :description => 'bar'
      }
    end

    it 'updates a configuration_script_source with an appropriate role' do
      api_basic_authorize action_identifier(:configuration_script_sources, :edit)

      run_patch(api_configuration_script_source_url(nil, config_script_src), [params])

      expected = {
        'success' => true,
        'message' => a_string_including('Updating ConfigurationScriptSource'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/configuration_script_sources/:id' do
    let(:params) do
      {
        :name        => 'foo',
        :description => 'bar'
      }
    end

    it 'updates a configuration_script_source with an appropriate role' do
      api_basic_authorize action_identifier(:configuration_script_sources, :edit)

      run_post(api_configuration_script_source_url(nil, config_script_src), :action => 'edit', :resource => params)

      expected = {
        'success' => true,
        'message' => a_string_including('Updating ConfigurationScriptSource'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires that the type support update_in_provider_queue' do
      config_script_src = FactoryGirl.create(:configuration_script_source)
      api_basic_authorize action_identifier(:configuration_script_sources, :edit)

      run_post(api_configuration_script_source_url(nil, config_script_src), :action => 'edit', :resource => params)

      expected = {
        'success' => false,
        'message' => "Update not supported for ConfigurationScriptSource id:#{config_script_src.id} name: '#{config_script_src.name}'"
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids updating a configuration_script_source without an appropriate role' do
      api_basic_authorize

      run_post(api_configuration_script_source_url(nil, config_script_src), :action => 'edit', :resource => params)

      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids refresh without an appropriate role' do
      api_basic_authorize

      run_post(api_configuration_script_source_url(nil, config_script_src), :action => 'refresh')

      expect(response).to have_http_status(:forbidden)
    end

    it 'can refresh a configuration_script_source with an appropriate role' do
      api_basic_authorize action_identifier(:configuration_script_sources, :refresh)

      run_post(api_configuration_script_source_url(nil, config_script_src), :action => :refresh)

      expected = {
        'success'   => true,
        'message'   => /Refreshing ConfigurationScriptSource/,
        'task_id'   => a_kind_of(String),
        'task_href' => /task/,
        'tasks'     => [a_hash_including('id' => a_kind_of(String), 'href' => /tasks/)]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can delete a configuration_script_source with an appropriate role' do
      api_basic_authorize action_identifier(:configuration_script_sources, :delete)

      run_post(api_configuration_script_source_url(nil, config_script_src), :action => 'delete')

      expected = {
        'success' => true,
        'message' => a_string_including('Deleting ConfigurationScriptSource'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires that the type support delete_in_provider_queue' do
      config_script_src = FactoryGirl.create(:configuration_script_source)
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :delete, :post)

      run_post(api_configuration_script_source_url(nil, config_script_src), :action => 'delete', :resource => params)

      expected = {
        'success' => false,
        'message' => "Delete not supported for ConfigurationScriptSource id:#{config_script_src.id} name: '#{config_script_src.name}'"
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids configuration script source delete without an appropriate role' do
      api_basic_authorize

      run_post(api_configuration_script_source_url(nil, config_script_src), :action => 'delete')

      expect(response).to have_http_status(:forbidden)
    end

    let(:create_params) do
      {
        :manager_resource => { :href => api_provider_url(nil, manager) },
        :description      => 'Description',
        :name             => 'My Project',
        :related          => {}
      }
    end

    it 'creates a configuration script source with appropriate role' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :create, :post)

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Creating ConfigurationScriptSource'),
            'task_id' => a_kind_of(String)
          )
        ]
      }
      run_post(api_configuration_script_sources_url, create_params)

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'create a new configuration script source with manager_resource id' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :create, :post)
      create_params[:manager_resource] = { :id => manager.id }

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => "Creating ConfigurationScriptSource for Manager id:#{manager.id} name: '#{manager.name}'",
            'task_id' => a_kind_of(String)
          )
        ]
      }
      run_post(api_configuration_script_sources_url, create_params)

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'can create new configuration script sources in bulk' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :create, :post)

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Creating ConfigurationScriptSource'),
            'task_id' => a_kind_of(String)
          ),
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Creating ConfigurationScriptSource'),
            'task_id' => a_kind_of(String)
          )
        ]
      }
      run_post(api_configuration_script_sources_url, :resources => [create_params, create_params])

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'requires a manager_resource to be specified' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :create, :post)

      run_post(api_configuration_script_sources_url, :resources => [create_params.except(:manager_resource)])

      expected = {
        'results' => [{
          'success' => false,
          'message' => 'Must supply a manager resource'
        }]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires a valid manager' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :create, :post)
      create_params[:manager_resource] = { :href => api_user_url(nil, 10) }

      run_post(api_configuration_script_sources_url, :resources => [create_params])

      expected = {
        'results' => [{
          'success' => false,
          'message' => 'Must specify a valid manager_resource href or id'
        }]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids creation of new configuration script source without an appropriate role' do
      api_basic_authorize

      run_post(api_configuration_script_sources_url, create_params)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/configuration_script_sources/:id' do
    it 'can delete a configuration_script_source with an appropriate role' do
      api_basic_authorize action_identifier(:configuration_script_sources, :delete, :resource_actions, :delete)

      run_delete(api_configuration_script_source_url(nil, config_script_src))

      expect(response).to have_http_status(:no_content)
    end

    it 'forbids configuration_script_source delete without an appropriate role' do
      api_basic_authorize

      run_delete(api_configuration_script_source_url(nil, config_script_src))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/configuration_script_sources/:id/configuration_script_payloads' do
    let(:payload) { FactoryGirl.create(:configuration_script_payload) }

    before do
      config_script_src.configuration_script_payloads << payload
    end

    it 'forbids configuration_script_payload retrievel without an appropriate role' do
      api_basic_authorize

      run_get(api_configuration_script_source_configuration_script_payloads_url(nil, config_script_src))

      expect(response).to have_http_status(:forbidden)
    end

    it 'lists all configuration_script_payloads belonging to a configuration_script_source' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_sources, :configuration_script_payloads, :read, :get)

      run_get(api_configuration_script_source_configuration_script_payloads_url(nil, config_script_src))

      expected = {
        'resources' => [
          {'href' => a_string_including(api_configuration_script_source_configuration_script_payload_url(nil, config_script_src.compressed_id, payload.compressed_id))}
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can filter on region_number' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_sources, :configuration_script_payloads, :read, :get)

      run_get(
        api_configuration_script_source_configuration_script_payloads_url(nil, config_script_src),
        :filter => ["region_number=#{payload.region_number}"]
      )

      expected = {
        'subcount'  => 1,
        'resources' => [
          {'href' => a_string_including(api_configuration_script_source_configuration_script_payload_url(nil, config_script_src.compressed_id, payload.compressed_id))}
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)

      run_get(
        api_configuration_script_source_configuration_script_payloads_url(nil, config_script_src),
        :filter => ["region_number=#{payload.region_number + 1}"]
      )

      expected = {
        'subcount'  => 0,
        'resources' => []
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
