RSpec.describe 'Configuration Script Payloads API' do
  describe 'GET /api/configuration_script_payloads' do
    it 'lists all the configuration script payloads with an appropriate role' do
      script_payload = FactoryBot.create(:configuration_script_payload)
      api_basic_authorize collection_action_identifier(:configuration_script_payloads, :read, :get)

      get(api_configuration_script_payloads_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'configuration_script_payloads',
        'resources' => [
          hash_including('href' => api_configuration_script_payload_url(nil, script_payload))
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to configuration script payloads without an appropriate role' do
      api_basic_authorize

      get(api_configuration_script_payloads_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/configuration_script_payloads/:id' do
    it 'will show an ansible script_payload with an appropriate role' do
      script_payload = FactoryBot.create(:configuration_script_payload)
      api_basic_authorize action_identifier(:configuration_script_payloads, :read, :resource_actions, :get)

      get(api_configuration_script_payload_url(nil, script_payload))

      expect(response.parsed_body)
        .to include('href' => api_configuration_script_payload_url(nil, script_payload))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to an ansible script_payload without an appropriate role' do
      script_payload = FactoryBot.create(:configuration_script_payload)
      api_basic_authorize

      get(api_configuration_script_payload_url(nil, script_payload))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/configuration_script_payloads/:id/authentications' do
    it 'returns the configuration script sources authentications' do
      authentication = FactoryBot.create(:authentication)
      playbook = FactoryBot.create(:configuration_script_payload, :authentications => [authentication])
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :read, :get)

      get(api_configuration_script_payload_authentications_url(nil, playbook), :params => { :expand => 'resources' })

      expected = {
        'resources' => [
          a_hash_including('id' => authentication.id.to_s)
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/configuration_script_payloads/:id/authentications' do
    let(:provider) { FactoryBot.create(:provider_ansible_tower, :with_authentication) }
    let(:manager) { provider.managers.first }
    let(:playbook) { FactoryBot.create(:configuration_script_payload, :manager => manager) }
    let(:params) do
      {
        :action      => 'create',
        :description => "Description",
        :name        => "A Credential",
        :related     => {},
        :type        => 'ManageIQ::Providers::AnsibleTower::AutomationManager::Credential'
      }
    end

    it 'requires that the type support create_in_provider_queue' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :create)

      post(api_configuration_script_payload_authentications_url(nil, playbook), :params => { :type => 'Authentication' })

      expected = {
        'results' => [
          { 'success' => false, 'message' => 'type not currently supported' }
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'creates a new authentication with an appropriate role' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :create)

      post(api_configuration_script_payload_authentications_url(nil, playbook), :params => params)

      expected = {
        'results' => [a_hash_including(
          'success' => true,
          'message' => 'Creating Authentication',
          'task_id' => a_kind_of(String)
        )]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can create multiple authentications with an appropriate role' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :create)

      post(api_configuration_script_payload_authentications_url(nil, playbook), :params => { :resources => [params, params] })

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => 'Creating Authentication',
            'task_id' => a_kind_of(String)
          ),
          a_hash_including(
            'success' => true,
            'message' => 'Creating Authentication',
            'task_id' => a_kind_of(String)
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'cannot create an authentication without appropriate role' do
      api_basic_authorize

      post(api_configuration_script_payload_authentications_url(nil, playbook), :params => { :resources => [params] })

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/configuration_script_payloads/:id/authentications/:id' do
    it 'returns a specific authentication' do
      authentication = FactoryBot.create(:authentication)
      playbook = FactoryBot.create(:configuration_script_payload, :authentications => [authentication])
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :read, :get)

      get(api_configuration_script_payload_authentication_url(nil, playbook, authentication))

      expected = {
        'id' => authentication.id.to_s
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
