describe 'Middleware Messagings API' do
  let(:messaging) { FactoryGirl.create(:middleware_messaging) }

  describe '/' do
    it 'forbids access without an appropriate role' do
      api_basic_authorize

      get api_middleware_messagings_url

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns an empty listing of messagings' do
      api_basic_authorize collection_action_identifier(:middleware_messagings, :read, :get)

      get api_middleware_messagings_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'name'      => 'middleware_messagings',
        'count'     => 0,
        'resources' => [],
        'subcount'  => 0
      )
    end

    it 'returns a a listing of messagings' do
      messaging

      api_basic_authorize collection_action_identifier(:middleware_messagings, :read, :get)

      get api_middleware_messagings_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'name'      => 'middleware_messagings',
        'count'     => 1,
        'resources' => [{
          'href' => api_middleware_messaging_url(nil, messaging.compressed_id)
        }],
        'subcount'  => 1
      )
    end
  end

  describe '/:id' do
    it 'forbids access to a messaging without an appropriate role' do
      api_basic_authorize

      get api_middleware_messaging_url(nil, messaging.compressed_id)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the attributes of one messaging' do
      api_basic_authorize action_identifier(:middleware_messagings, :read, :resource_actions, :get)

      get api_middleware_messaging_url(nil, messaging.id)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq messaging.compressed_id
      expect(response.parsed_body).to include('href' => api_middleware_messaging_url(nil, messaging.compressed_id))
    end
  end
end
