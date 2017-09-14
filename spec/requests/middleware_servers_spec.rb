describe 'Middleware Servers API' do
  let(:server) { FactoryGirl.create(:middleware_server) }


  describe '/' do
    it 'forbids access without an appropriate role' do
      api_basic_authorize

      run_get api_middleware_servers_url

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns an empty listing of servers' do
      api_basic_authorize collection_action_identifier(:middleware_servers, :read, :get)

      run_get api_middleware_servers_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'name'      => 'middleware_servers',
        'count'     => 0,
        'resources' => [],
        'subcount'  => 0
      )
    end

    it 'returns a a listing of servers' do
      server

      api_basic_authorize collection_action_identifier(:middleware_servers, :read, :get)

      run_get api_middleware_servers_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'name'      => 'middleware_servers',
        'count'     => 1,
        'resources' => [{
          'href' => api_middleware_server_url(nil, server.compressed_id)
        }],
        'subcount'  => 1
      )
    end
  end

  describe '/:id' do
    it 'returns the attributes of one server' do
      api_basic_authorize

      run_get api_middleware_server_url(nil, server.id)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq server.compressed_id
      expect(response.parsed_body).to include(
        'href'       => api_middleware_server_url(nil, server.compressed_id),
        'name'       => server.name,
        'feed'       => server.feed,
        'properties' => server.properties,
      )
    end
  end
end
