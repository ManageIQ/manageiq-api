describe 'Middleware Datasources API' do
  let(:datasource) { FactoryGirl.create(:middleware_datasource) }

  describe '/' do
    it 'forbids access without an appropriate role' do
      api_basic_authorize

      get api_middleware_datasources_url

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns an empty listing of datasources' do
      api_basic_authorize collection_action_identifier(:middleware_datasources, :read, :get)

      get api_middleware_datasources_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'name'      => 'middleware_datasources',
        'count'     => 0,
        'resources' => [],
        'subcount'  => 0
      )
    end

    it 'returns a listing of datasources' do
      datasource

      api_basic_authorize collection_action_identifier(:middleware_datasources, :read, :get)

      get api_middleware_datasources_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'name'      => 'middleware_datasources',
        'count'     => 1,
        'resources' => [{
          'href' => api_middleware_datasource_url(nil, datasource.compressed_id)
        }],
        'subcount'  => 1
      )
    end
  end

  describe '/:id' do
    it 'forbids access to a datasource without an appropriate role' do
      api_basic_authorize

      get api_middleware_datasource_url(nil, datasource.compressed_id)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the attributes of one datasource' do
      api_basic_authorize action_identifier(:middleware_datasources, :read, :resource_actions, :get)

      get api_middleware_datasource_url(nil, datasource.compressed_id)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq datasource.compressed_id
      expect(response.parsed_body).to include('href' => api_middleware_datasource_url(nil, datasource.compressed_id))
    end
  end
end
