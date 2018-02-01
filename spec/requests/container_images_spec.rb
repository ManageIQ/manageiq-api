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

  context 'POST /api/container_images with action scan' do
    let(:provider) { FactoryGirl.create(:ems_kubernetes) }
    let(:container_image) { FactoryGirl.create(:container_image, :ext_management_system => provider) }
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
        "message" => "ContainerImage id:#{container_image.id} name:'#{container_image.name}' failed to start scanning",
      }
      expect(response.parsed_body).to include(expected)
    end

    it "scan a Container Image" do
      api_basic_authorize(action_identifier(:container_images, :scan, :resource_actions, :post))
      # MiqEventDefinition that is called for scanning container images.
      _med = FactoryGirl.create(:miq_event_definition, :name => "request_containerimage_scan")
      post valid_image_url, :params => { :action => "scan" }

      expected = {
        "success"   => true,
        "message"   => "ContainerImage id:#{container_image.id} name:'#{container_image.name}' scanning",
        "href"      => api_container_image_url(nil, container_image),
        "task_id"   => anything,
        "task_href" => a_string_matching(api_tasks_url)
      }
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'POST /api/container_images/<id> with openscap_scan_results action' do
    let(:provider) { FactoryGirl.create(:ems_kubernetes) }
    let(:cimage) { FactoryGirl.create(:container_image, :ext_management_system => provider) }
    let(:unscanned_cimage) { FactoryGirl.create(:container_image, :ext_management_system => provider) }
    let(:valid_image_url) { api_container_image_url(nil, cimage) }
    let(:valid_unscanned_image_url) { api_container_image_url(nil, unscanned_cimage) }

    it "returns empty list if the image doesn't have any OpenscapResultRule's" do
      api_basic_authorize(action_identifier(:container_images, :openscap_scan_results, :resource_actions, :post))
      post(valid_unscanned_image_url, :params => { :action => "openscap_scan_results" })
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['message']).to include("summary" => [])
    end

    it "returns a list of openscap_result_summaries" do
      blob = FactoryGirl.create(:binary_blob,
                                :binary => "blob",
                                :name   => "test_blob")

      openscap_result = FactoryGirl.create(:openscap_result_skip_callback,
                                           :binary_blob        => blob,
                                           :resource_id        => cimage.id,
                                           :resource_type      => "ContainerImage",
                                           :container_image_id => cimage.id)

      rule1 = FactoryGirl.create(:openscap_rule_result,
                                 :openscap_result => openscap_result,
                                 :name            => "First Rule",
                                 :severity        => "High",
                                 :result          => "success")

      rule2 = FactoryGirl.create(:openscap_rule_result,
                                 :openscap_result => openscap_result,
                                 :name            => "Second Rule",
                                 :severity        => "Medium",
                                 :result          => "fail")

      cimage.openscap_result = openscap_result
      cimage.openscap_result.openscap_rule_results << rule1
      cimage.openscap_result.openscap_rule_results << rule2

      api_basic_authorize(action_identifier(:container_images, :openscap_scan_results, :resource_actions, :post))
      post(valid_image_url, :params => { :action => "openscap_scan_results" })
      expect(response).to have_http_status(:ok)
      summary = [a_hash_including("name" => rule1.name, "severity" => rule1.severity, "result" => rule1.result),
                 a_hash_including("name" => rule2.name, "severity" => rule2.severity, "result" => rule2.result)]
      expect(response.parsed_body['message']).to include("summary" => summary)
    end
  end
end
