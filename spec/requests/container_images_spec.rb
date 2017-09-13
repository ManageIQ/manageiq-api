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

  context 'POST /api/container_images/scan' do
    let(:provider) { FactoryGirl.create(:ems_kubernetes) }
    let(:container_image) { FactoryGirl.create(:container_image, :ext_management_system => provider) }
    let(:invalid_image_url) { api_provider_container_image_url(nil, provider, container_image.id + 1) }
    let(:valid_image_url) { api_provider_container_image_url(nil, provider, container_image) }

    it "responds with 404 Not Found for an invalid container image" do
      api_basic_authorize(action_identifier(:container_images, :scan, :subresource_actions, :post))

      post(invalid_image_url, :params => { :action => "scan" })

      expect(response).to have_http_status(:not_found)
    end

    it "doesn't scan a Container Image without appropriate role" do
      api_basic_authorize

      post(valid_image_url, :params => { :action => "scan" })

      expect(response).to have_http_status(:forbidden)
    end

    it "reports failed scanning initiation without MiqEventDefinition" do
      api_basic_authorize(action_identifier(:container_images, :scan, :subresource_actions, :post))
      post valid_image_url, :params => { :action => "scan" }
      expected = {
        "success"   => false,
        "message"   => "ContainerImage id:#{container_image.id} name:'#{container_image.name}' failed to start scanning",
        "parent_id" => hash_including("id" => provider.id.to_s)
      }
      expect(response.parsed_body).to include(expected)
    end

    it "scan a Container Image" do
      api_basic_authorize(action_identifier(:container_images, :scan, :subresource_actions, :post))
      # MiqEventDefinition that is called for scanning container images.
      _med = FactoryGirl.create(:miq_event_definition, :name => "request_containerimage_scan")
      post valid_image_url, :params => { :action => "scan" }

      expected = {
        "success"   => true,
        "message"   => "ContainerImage id:#{container_image.id} name:'#{container_image.name}' scanning",
        "parent_id" => hash_including("id" => provider.id.to_s),
        "task_id"   => hash_including("target_id" => container_image.id.to_s)
      }
      expect(response.parsed_body).to include(expected)
    end
  end
end
