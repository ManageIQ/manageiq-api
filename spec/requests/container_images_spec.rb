describe "Container Images API" do
  context 'GET /api/container_images' do
    it 'forbids access to container images without an appropriate role' do
      api_basic_authorize

      get(api_container_images_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns container images with an appropriate role' do
      container_images = FactoryGirl.create(:container_image)
      api_basic_authorize(collection_action_identifier(:container_images, :read, :get))

      get(api_container_images_url)

      expected = {
        'resources' => [{'href' => api_container_image_url(nil, container_images)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'GET /api/container_images' do
    let(:container_image) { FactoryGirl.create(:container_image) }

    it 'forbids access to a container image without an appropriate role' do
      api_basic_authorize

      get(api_container_image_url(nil, container_image))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the container image with an appropriate role' do
      api_basic_authorize(action_identifier(:container_images, :read, :resource_actions, :get))

      get(api_container_image_url(nil, container_image))

      expected = {
        'href' => api_container_image_url(nil, container_image)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
