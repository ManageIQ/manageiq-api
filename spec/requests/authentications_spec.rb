RSpec.describe 'Authentications API' do
  include Spec::Support::SupportsHelper

  let(:manager) { FactoryBot.create(:automation_manager_ansible_tower) }
  let(:auth) { FactoryBot.create(:ansible_cloud_credential, :resource => manager) }
  let(:auth_2) { FactoryBot.create(:ansible_cloud_credential, :resource => manager) }

  describe 'GET/api/authentications' do
    it 'lists all the authentication configuration script bases with an appropriate role' do
      auth = FactoryBot.create(:authentication)
      api_basic_authorize collection_action_identifier(:authentications, :read, :get)

      get(api_authentications_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'authentications',
        'resources' => [hash_including('href' => api_authentication_url(nil, auth))]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to authentication configuration script bases without an appropriate role' do
      api_basic_authorize

      get(api_authentications_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/authentications/:id' do
    it 'will show an authentication configuration script base' do
      api_basic_authorize action_identifier(:authentications, :read, :resource_actions, :get),
                          action_identifier(:authentications, :edit)
      href = api_authentication_url(nil, auth)

      get(href)

      expected = {
        'href'    => href,
        'actions' => [
          { 'name' => 'edit', 'method' => 'post', 'href' => href },
          { 'name' => 'edit', 'method' => 'patch', 'href' => href },
          { 'name' => 'edit', 'method' => 'put', 'href' => href }
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to an authentication configuration script base' do
      api_basic_authorize

      get(api_authentication_url(nil, auth))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/authentications' do
    let(:params) do
      {
        :id          => auth.id,
        :description => 'Description',
        :name        => 'Updated Credential'
      }
    end

    it 'will delete an authentication' do
      api_basic_authorize collection_action_identifier(:authentications, :delete, :post)
      stub_supports(auth, :delete)

      post(api_authentications_url, :params => { :action => 'delete', :resources => [{ 'id' => auth.id }] })

      expect_multiple_action_result(1, :success => true, :task => true, :message => /Deleting Authentication/)
    end

    it 'raises a not found for nonexistent authentication' do
      api_basic_authorize collection_action_identifier(:authentications, :delete, :post)

      post(api_authentication_url(nil, 0), :params => { :action => 'delete' })

      expect(response).to have_http_status(:not_found)
    end

    it 'verifies that the type is supported' do
      api_basic_authorize collection_action_identifier(:authentications, :delete, :post)
      auth = FactoryBot.create(:authentication)
      stub_supports_not(auth, :delete)

      post(api_authentications_url, :params => { :action => 'delete', :resources => [{ 'id' => auth.id }] })

      expect_multiple_action_result(1, :success => false, :message => /Feature not available\/supported/)
    end

    it 'will delete multiple authentications' do
      api_basic_authorize collection_action_identifier(:authentications, :delete, :post)
      stub_supports(auth, :delete)
      stub_supports(auth_2, :delete)

      post(api_authentications_url, :params => {:action => 'delete', :resources => [{'id' => auth.id}, {'id' => auth_2.id}]})
      expect_multiple_action_result(2, :task => true, :success => true, :message => 'Deleting Authentication')
    end

    it 'will forbid deletion to an authentication without appropriate role' do
      auth = FactoryBot.create(:authentication)
      api_basic_authorize

      post(api_authentications_url, :params => { :action => 'delete', :resources => [{ 'id' => auth.id }] })
      expect(response).to have_http_status(:forbidden)
    end

    it 'can update an authentication with an appropriate role' do
      api_basic_authorize collection_action_identifier(:authentications, :edit)
      stub_supports(auth, :update)

      post(api_authentications_url, :params => { :action => 'edit', :resources => [params] })

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Updating Authentication'),
            'task_id' => a_kind_of(String)
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can update an authentication with an appropriate role' do
      params2 = params.dup.merge(:id => auth_2.id)
      api_basic_authorize collection_action_identifier(:authentications, :edit)
      stub_supports(auth_2, :update)

      post(api_authentications_url, :params => { :action => 'edit', :resources => [params, params2] })

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Updating Authentication'),
            'task_id' => a_kind_of(String)
          ),
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Updating Authentication'),
            'task_id' => a_kind_of(String)
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will forbid update to an authentication without appropriate role' do
      api_basic_authorize

      post(api_authentications_url, :params => { :action => 'edit', :resources => [params] })

      expect(response).to have_http_status(:forbidden)
    end

    let(:create_params) do
      {
        :action           => 'create',
        :description      => "Description",
        :name             => "A Credential",
        :related          => {},
        :type             => 'ManageIQ::Providers::AnsibleTower::AutomationManager::Credential',
        :manager_resource => { :href => api_provider_url(nil, manager) }
      }
    end

    it 'requires a manager resource when creating an authentication' do
      api_basic_authorize collection_action_identifier(:authentications, :create, :post)

      post(api_authentications_url, :params => { :action => 'create', :type => 'Authentication' })

      expected = {
        'results' => [
          { 'success' => false, 'message' => 'must supply a manager resource' }
        ]
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires that the type support create_in_provider_queue' do
      api_basic_authorize collection_action_identifier(:authentications, :create, :post)

      post(api_authentications_url, :params => { :action => 'create', :type => 'Authentication', :manager_resource => { :href => api_provider_url(nil, manager) } })

      expected = {
        'results' => [
          { 'success' => false, 'message' => 'Create for Authentications: Feature not available/supported' }
        ]
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'can create an authentication' do
      api_basic_authorize collection_action_identifier(:authentications, :create, :post)

      stub_supports(create_params[:type].safe_constantize, :create)

      expected = {
        'results' => [a_hash_including(
          'success' => true,
          'message' => 'Creating Authentication',
          'task_id' => a_kind_of(String)
        )]
      }
      post(api_authentications_url, :params => create_params)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'creates and fails in a single request' do
      api_basic_authorize collection_action_identifier(:authentications, :create, :post)

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => 'Creating Authentication',
            'task_id' => a_kind_of(String)
          ),
          a_hash_including(
            'success' => false,
            'message' => 'must supply a manager resource'
          )
        ]
      }
      post(api_authentications_url, :params => {:resources => [create_params, create_params.except(:manager_resource)]})

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires a valid manager_resource' do
      api_basic_authorize collection_action_identifier(:authentications, :create, :post)
      create_params[:manager_resource] = { :href => '1' }

      expected = {
        'results' => [
          a_hash_including(
            'success' => false,
            'message' => 'invalid manager_resource href specified',
          )
        ]
      }
      post(api_authentications_url, :params => { :resources => [create_params] })

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will forbid creation of an authentication without appropriate role' do
      api_basic_authorize

      post(api_authentications_url, :params => { :action => 'create' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can refresh multiple authentications with an appropriate role' do
      api_basic_authorize collection_action_identifier(:authentications, :refresh, :post)

      post(api_authentications_url, :params => { :action => :refresh, :resources => [{ :id => auth.id}, {:id => auth_2.id}] })

      expected = {
        'results' => [
          a_hash_including(
            'success'   => true,
            'message'   => a_string_including("Refreshing Authentication id: #{auth.id}"),
            'task_id'   => a_kind_of(String),
            'task_href' => /task/,
            'tasks'     => [a_hash_including('id' => a_kind_of(String), 'href' => /task/)]
          ),
          a_hash_including(
            'success'   => true,
            'message'   => a_string_including("Refreshing Authentication id: #{auth_2.id}"),
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

  describe 'PUT /api/authentications/:id' do
    let(:params) do
      {
        :description => 'Description',
        :name        => 'Updated Credential'
      }
    end

    it 'can update an authentication with an appropriate role' do
      api_basic_authorize collection_action_identifier(:authentications, :edit)
      stub_supports(auth, :update)

      put(api_authentication_url(nil, auth), :params => { :resource => params })

      expected = {
        'success' => true,
        'message' => a_string_including('Updating Authentication'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'PATCH /api/authentications/:id' do
    let(:params) do
      {
        :action      => 'edit',
        :description => 'Description',
        :name        => 'Updated Credential'
      }
    end

    it 'can update an authentication with an appropriate role' do
      api_basic_authorize collection_action_identifier(:authentications, :edit)
      stub_supports(auth, :update)

      patch(api_authentication_url(nil, auth), :params => [params])

      expected = {
        'success' => true,
        'message' => a_string_including('Updating Authentication'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/authentications/:id' do
    let(:params) do
      {
        :description => 'Description',
        :name        => 'Updated Credential'
      }
    end

    it 'will delete an authentication' do
      api_basic_authorize action_identifier(:authentications, :delete, :resource_actions, :post)
      stub_supports(auth, :delete)

      post(api_authentication_url(nil, auth), :params => { :action => 'delete' })

      expect_single_action_result(:success => true, :task => true, :message => 'Deleting Authentication')
    end

    it 'will not delete an authentication without an appropriate role' do
      api_basic_authorize

      post(api_authentication_url(nil, auth), :params => { :action => 'delete' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can update an authentication with an appropriate role' do
      api_basic_authorize collection_action_identifier(:authentications, :edit)
      stub_supports(auth, :update)

      post(api_authentication_url(nil, auth), :params => { :action => 'edit', :resource => params })

      expected = {
        'success' => true,
        'message' => a_string_including('Updating Authentication'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires that the type support update_in_provider_queue' do
      api_basic_authorize collection_action_identifier(:authentications, :edit)
      auth = FactoryBot.create(:authentication)
      stub_supports_not(auth, :update)

      post(api_authentication_url(nil, auth), :params => { :action => 'edit', :resource => params })

      expect_bad_request("Update for Authentication id: #{auth.id} name: '#{auth.name}': Feature not available/supported")
    end

    it 'will forbid update to an authentication without appropriate role' do
      api_basic_authorize

      post(api_authentication_url(nil, auth), :params => { :action => 'edit', :resource => params })

      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids refresh without an appropriate role' do
      api_basic_authorize

      post(api_authentication_url(nil, auth), :params => { :action => :refresh })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can refresh a authentications with an appropriate role' do
      api_basic_authorize action_identifier(:authentications, :refresh)

      post(api_authentication_url(nil, auth), :params => { :action => :refresh })

      expected = {
        'success'   => true,
        'message'   => /Refreshing Authentication/,
        'task_id'   => a_kind_of(String),
        'task_href' => /task/,
        'tasks'     => [a_hash_including('id' => a_kind_of(String), 'href' => /tasks/)]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'DELETE /api/authentications/:id' do
    it 'will delete an authentication' do
      auth = FactoryBot.create(:embedded_ansible_openstack_credential)
      stub_supports(auth, :delete)

      api_basic_authorize action_identifier(:authentications, :delete, :resource_actions, :delete)

      delete(api_authentication_url(nil, auth))

      expect(response).to have_http_status(:no_content)
    end

    it 'will not delete an authentication without an appropriate role' do
      auth = FactoryBot.create(:authentication)
      api_basic_authorize

      delete(api_authentication_url(nil, auth))

      expect(response).to have_http_status(:forbidden)
    end

    it 'will raise an error if the authentication does not exist' do
      api_basic_authorize action_identifier(:authentications, :delete, :resource_actions, :delete)

      delete(api_authentication_url(nil, 999_999))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'OPTIONS /api/authentications' do
    it 'returns expected and additional attributes' do
      options(api_authentications_url)

      additional_options = {
        "credential_types" => credential_types
      }
      expect_options_results(:authentications, additional_options)
    end
  end

  def credential_types
    credential_subclasses = Authentication.descendants.select { |d| d.try(:credential_type) }.sort_by(&:name)

    credential_subclasses.each_with_object({}) do |klass, credential_hash|
      unless credential_hash.key?(klass.credential_type.to_sym)
        credential_hash[klass.credential_type.to_sym] = {}
      end

      if defined? klass::API_OPTIONS
        klass::API_OPTIONS.tap do |options|
          options[:attributes].each do |_k, val|
            val[:type] = val[:type].to_s if val && val[:type]
          end
          credential_hash[klass.credential_type.to_sym].merge!({klass.name => options})
        end
      end
    end.deep_stringify_keys
  end
end 