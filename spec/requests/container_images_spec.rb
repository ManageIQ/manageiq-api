describe "Container Images API" do
  context 'GET /api/container_images' do
    it 'forbids access to container images without an appropriate role' do
      api_basic_authorize

      get(api_container_images_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns container images with an appropriate role' do
      container_images = FactoryBot.create(:container_image)
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
    let(:container_image) { FactoryBot.create(:container_image) }

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

  context 'POST /api/container_images with action scan' do
    let(:provider) { FactoryBot.create(:ems_kubernetes) }
    let(:container_image) { FactoryBot.create(:container_image, :ext_management_system => provider) }
    let(:invalid_image_url) { api_container_image_url(nil, container_image.id + 1) }
    let(:valid_image_url) { api_container_image_url(nil, container_image) }

    it "responds with 404 Not Found for an invalid container image" do
      api_basic_authorize(action_identifier(:container_images, :scan, :resource_actions, :post))

      post(invalid_image_url, :params => { :action => "scan" })

      expect(response).to have_http_status(:not_found)
    end

    it "doesn't scan a Container Image without appropriate role" do
      api_basic_authorize

      post(valid_image_url, :params => { :action => "scan" })

      expect(response).to have_http_status(:forbidden)
    end

    it "reports failed scanning initiation without MiqEventDefinition" do
      api_basic_authorize(action_identifier(:container_images, :scan, :resource_actions, :post))
      post valid_image_url, :params => { :action => "scan" }
      expected = {
        "success" => false,
        "message" => "Failed Scanning Container Image id: #{container_image.id} name: '#{container_image.name}'",
      }
      expect(response.parsed_body).to include(expected)
    end

    it "scan a Container Image" do
      api_basic_authorize(action_identifier(:container_images, :scan, :resource_actions, :post))
      # MiqEventDefinition that is called for scanning container images.
      _med = FactoryBot.create(:miq_event_definition, :name => "request_containerimage_scan")
      post valid_image_url, :params => { :action => "scan" }

      expected = {
        "success"   => true,
        "message"   => "Scanning Container Image id: #{container_image.id} name: '#{container_image.name}'",
        "href"      => api_container_image_url(nil, container_image),
        "task_id"   => anything,
        "task_href" => a_string_matching(api_tasks_url)
      }
      expect(response.parsed_body).to include(expected)
    end
  end

  it_behaves_like "a check compliance action", "container_image", :container_image, "ContainerImage"
end
