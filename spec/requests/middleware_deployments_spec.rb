describe 'Middleware Deployments API' do
  let(:deployment) { FactoryGirl.create(:middleware_deployment) }

  describe '/' do
    it 'forbids access without an appropriate role' do
      api_basic_authorize

      get api_middleware_deployments_url

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns an empty listing of deployments' do
      api_basic_authorize collection_action_identifier(:middleware_deployments, :read, :get)

      get api_middleware_deployments_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'name'      => 'middleware_deployments',
        'count'     => 0,
        'resources' => [],
        'subcount'  => 0
      )
    end

    it 'returns a a listing of deployments' do
      deployment

      api_basic_authorize collection_action_identifier(:middleware_deployments, :read, :get)

      get api_middleware_deployments_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'name'      => 'middleware_deployments',
        'count'     => 1,
        'resources' => [{
          'href' => api_middleware_deployment_url(nil, deployment)
        }],
        'subcount'  => 1
      )
    end
  end

  describe '/:id' do
    it 'forbids access to a deployment without an appropriate role' do
      api_basic_authorize

      get api_middleware_deployment_url(nil, deployment)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the attributes of one deployment' do
      api_basic_authorize action_identifier(:middleware_deployments, :read, :resource_actions, :get)

      get api_middleware_deployment_url(nil, deployment)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'id'     => deployment.id.to_s,
        'ems_id' => deployment.ems_id.to_s,
        'href'   => api_middleware_deployment_url(nil, deployment),
        'name'   => deployment.name
      )
    end
  end
end
