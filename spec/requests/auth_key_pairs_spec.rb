RSpec.describe "Auth Key Pairs API" do
  let(:akp) { FactoryBot.create(:auth_key_pair_cloud, :resource => FactoryBot.create(:ems_cloud)) }

  describe 'GET /api/auth_key_pairs' do
    before { akp }

    context 'without an appropriate role' do
      it 'does not list auth key pairs' do
        api_basic_authorize
        get(api_auth_key_pairs_url)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with an appropriate role' do
      before { api_basic_authorize collection_action_identifier(:auth_key_pairs, :read, :get) }

      it 'lists all auth key pairs' do
        get(api_auth_key_pairs_url)

        expected = {
          'count'     => 1,
          'subcount'  => 1,
          'name'      => 'auth_key_pairs',
          'resources' => [
            hash_including('href' => api_auth_key_pair_url(nil, akp))
          ]
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end

  describe 'GET /api/auth_key_pairs/:id' do
    context 'without an appropriate role' do
      it 'does not let you query a custom button' do
        api_basic_authorize
        get(api_auth_key_pair_url(nil, akp))
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with an appropriate role' do
      before { api_basic_authorize action_identifier(:auth_key_pairs, :read, :resource_actions, :get) }

      it 'can query an auth key pair by its id' do
        get(api_auth_key_pair_url(nil, akp))

        expected = {
          'id'   => akp.id.to_s,
          'type' => "ManageIQ::Providers::CloudManager::AuthKeyPair"
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end

  describe 'POST /api/auth_key_pairs' do
    it 'can create auth_key_pairs' do
      api_basic_authorize collection_action_identifier(:auth_key_pairs, :create)

      post(api_auth_key_pairs_url, :params => {'name' => 'foo'})

      expect(response).to have_http_status(:ok)

      auth_key_pair = ManageIQ::Providers::CloudManager::AuthKeyPair.find(response.parsed_body['results'].first["id"])
      expect(auth_key_pair.name).to eq('foo')
    end

    it 'can delete auth_key_pairs' do
      api_basic_authorize action_identifier(:auth_key_pairs, :delete)

      post(api_auth_key_pair_url(nil, akp), :params => {'action' => 'delete'})

      expect_single_action_result(:success => true, :message => "Deleting", :task => true)
    end

    it 'will not allow unauthorized key pairs delete' do
      api_basic_authorize action_identifier(:auth_key_pairs, :edit)

      expect_forbidden_request do
        post(api_auth_key_pair_url(nil, akp), :params => {'action' => 'delete'})
      end
    end
  end

  describe 'PUT /api/auth_key_pairs/:id' do
    it 'can edit an auth key pair by id' do
      api_basic_authorize action_identifier(:auth_key_pairs, :edit)

      expect(akp.name).not_to eq('foo')
      put(api_auth_key_pair_url(nil, akp), :params => {'name' => 'foo'})
      expect(response).to have_http_status(:ok)
      expect(akp.reload.name).to eq('foo')
    end
  end

  describe 'DELETE /api/auth_key_pairs/:id' do
    it 'can delete an auth key pair by id' do
      api_basic_authorize action_identifier(:auth_key_pairs, :delete, :resource_actions, :delete)

      delete(api_auth_key_pair_url(nil, akp))

      expect(response).to have_http_status(:no_content)
    end
  end
end
