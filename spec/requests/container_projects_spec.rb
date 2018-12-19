describe "Container Projects API" do
  context 'GET /api/container_projects' do
    it 'forbids access to container projects without an appropriate role' do
      api_basic_authorize

      get(api_container_projects_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns container projects with an appropriate role' do
      container_project = FactoryBot.create(:container_project)
      api_basic_authorize(collection_action_identifier(:container_projects, :read, :get))

      get(api_container_projects_url)

      expected = {
        'resources' => [{'href' => api_container_project_url(nil, container_project)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'GET /api/container_projects' do
    let(:container_project) { FactoryBot.create(:container_project) }

    it 'forbids access to a container project without an appropriate role' do
      api_basic_authorize

      get(api_container_project_url(nil, container_project))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the container project with an appropriate role' do
      api_basic_authorize(action_identifier(:container_projects, :read, :resource_actions, :get))

      get(api_container_project_url(nil, container_project))

      expected = {
        'href' => api_container_project_url(nil, container_project)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
