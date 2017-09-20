describe 'Middleware Servers API' do
  let(:server) { FactoryGirl.create(:middleware_server) }

  describe '/' do
    it 'forbids access without an appropriate role' do
      api_basic_authorize

      get api_middleware_servers_url

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns an empty listing of servers' do
      api_basic_authorize collection_action_identifier(:middleware_servers, :read, :get)

      get api_middleware_servers_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'name'      => 'middleware_servers',
        'count'     => 0,
        'resources' => [],
        'subcount'  => 0
      )
    end

    it 'returns a a listing of servers' do
      server

      api_basic_authorize collection_action_identifier(:middleware_servers, :read, :get)

      get api_middleware_servers_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'name'      => 'middleware_servers',
        'count'     => 1,
        'resources' => [{
          'href' => api_middleware_server_url(nil, server)
        }],
        'subcount'  => 1
      )
    end
  end

  describe '/:id' do
    it 'forbids access to a server without an appropriate role' do
      api_basic_authorize

      get api_middleware_server_url(nil, server)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the attributes of one server' do
      api_basic_authorize action_identifier(:middleware_servers, :read, :resource_actions, :get)

      get api_middleware_server_url(nil, server)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'id'         => server.id.to_s,
        'href'       => api_middleware_server_url(nil, server),
        'name'       => server.name,
        'feed'       => server.feed,
        'properties' => server.properties,
      )
    end
  end
end
