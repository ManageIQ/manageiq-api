describe "Container Volumes API" do
  context 'GET /api/container_volumes' do
    it 'forbids access to container volumes without an appropriate role' do
      api_basic_authorize

      get(api_container_volumes_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns container volumes with an appropriate role' do
      container_volume = FactoryGirl.create(:container_volume)
      api_basic_authorize(collection_action_identifier(:container_volumes, :read, :get))

      get(api_container_volumes_url)

      expected = {
        'resources' => [{'href' => api_container_volume_url(nil, container_volume)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'GET /api/container_volumes' do
    let(:container_volume) { FactoryGirl.create(:container_volume) }

    it 'forbids access to a container volume without an appropriate role' do
      api_basic_authorize

      get(api_container_volume_url(nil, container_volume))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the container volume with an appropriate role' do
      api_basic_authorize(action_identifier(:container_volumes, :read, :resource_actions, :get))

      get(api_container_volume_url(nil, container_volume))

      expected = {
        'href' => api_container_volume_url(nil, container_volume)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
