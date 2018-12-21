describe "Container Groups API" do
  context 'GET /api/container_groups' do
    it 'forbids access to container groups without an appropriate role' do
      api_basic_authorize

      get(api_container_groups_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns container groups with an appropriate role' do
      container_groups = FactoryBot.create(:container_group)
      api_basic_authorize(collection_action_identifier(:container_groups, :read, :get))

      get(api_container_groups_url)

      expected = {
        'resources' => [{'href' => api_container_group_url(nil, container_groups)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'GET /api/container_groups' do
    let(:container_group) { FactoryBot.create(:container_group) }

    it 'forbids access to a container group without an appropriate role' do
      api_basic_authorize

      get(api_container_group_url(nil, container_group))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the container group with an appropriate role' do
      api_basic_authorize(action_identifier(:container_groups, :read, :resource_actions, :get))

      get(api_container_group_url(nil, container_group))

      expected = {
        'href' => api_container_group_url(nil, container_group)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
