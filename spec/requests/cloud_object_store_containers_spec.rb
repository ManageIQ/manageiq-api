describe "Cloud Object Store Containers API" do
  context 'GET /api/cloud_object_store_containers' do
    it 'forbids access to cloud object store containers without an appropriate role' do
      api_basic_authorize

      get(api_cloud_object_store_containers_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns cloud object store containers with an appropriate role' do
      cloud_object_store_container = FactoryGirl.create(:cloud_object_store_container)
      api_basic_authorize(collection_action_identifier(:cloud_object_store_containers, :read, :get))

      get(api_cloud_object_store_containers_url)

      expected = {
        'resources' => [{'href' => api_cloud_object_store_container_url(nil, cloud_object_store_container)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'GET /api/cloud_object_store_containers' do
    let(:cloud_object_store_container) { FactoryGirl.create(:cloud_object_store_container) }

    it 'forbids access to a cloud object store container without an appropriate role' do
      api_basic_authorize

      get(api_cloud_object_store_container_url(nil, cloud_object_store_container))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the cloud object store container with an appropriate role' do
      api_basic_authorize(action_identifier(:cloud_object_store_containers, :read, :resource_actions, :get))

      get(api_cloud_object_store_container_url(nil, cloud_object_store_container))

      expected = {
        'href' => api_cloud_object_store_container_url(nil, cloud_object_store_container)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
