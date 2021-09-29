describe "Volume Mappings API" do
  context "POST /api/volume_mappings" do
    it "with an invalid ems_id it responds with 404 Not Found" do
      api_basic_authorize(collection_action_identifier(:volume_mappings, :create))

      request = {
        "action"   => "create",
        "resource" => {
          "ems_id"            => nil,
          "cloud_volume_id"   => "1",
          "host_initiator_id" => "1",
        }
      }

      post(api_volume_mappings_url, :params => request)

      expect(response).to have_http_status(:bad_request)
    end

    it "creates new Volume Mapping" do
      api_basic_authorize(collection_action_identifier(:volume_mappings, :create))
      provider = FactoryBot.create(:ems_autosde, :name => 'Autosde')
      cloud_volume = FactoryBot.create(:cloud_volume)
      host_initiator = FactoryBot.create(:host_initiator)

      request = {
        "action"   => "create",
        "resource" => {
          "ems_id"            => provider.id,
          "cloud_volume_id"   => cloud_volume.id,
          "host_initiator_id" => host_initiator.id,
        }
      }

      post(api_volume_mappings_url, :params => request)

      expect_multiple_action_result(1, :success => true, :message => "Creating Host Initiator test_host_initiator for Provider: #{provider.name}", :task => true)
    end
  end

  context "GET /api/volume_mappings" do
    it "returns all volume mappings" do
      volume_mapping = FactoryBot.create(:volume_mapping)
      api_basic_authorize('volume_mapping_show_list')

      get(api_volume_mappings_url)

      expected = {
        "name"      => "volume_mappings",
        "resources" => [{"href" => api_volume_mapping_url(nil, volume_mapping)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  it "can delete a single volume mapiing" do
    volume_mapping = FactoryBot.create(:volume_mapping)

    api_basic_authorize action_identifier(:volume_mapping, :delete, :resource_actions, :post)

    post(api_volume_mapping_url(nil, volume_mapping), :params => {:action => "delete"})

    expected = {
      'message' => "Deleting Volume Mapping id:#{volume_mapping.id}",
      'success' => true,
      'task_id' => a_kind_of(String)
    }

    expect(response.parsed_body).to include(expected)
    expect(response).to have_http_status(:ok)
  end

  it "can delete volume mapping with DELETE as a resource action" do
    volume_mapping = FactoryBot.create(:volume_mapping)

    api_basic_authorize action_identifier(:volume_mapping, :delete, :resource_actions, :delete)

    delete api_volume_mapping_url(nil, volume_mapping)

    expect(response).to have_http_status(:no_content)
  end

  it "rejects delete request with DELETE as a resource action without appropriate role" do
    volume_mapping = FactoryBot.create(:volume_mapping)

    api_basic_authorize

    delete api_volume_mapping_url(nil, volume_mapping)

    expect(response).to have_http_status(:forbidden)
  end

  it 'DELETE will raise an error if the cloud volume does not exist' do
    api_basic_authorize action_identifier(:volume_mappings, :delete, :resource_actions, :delete)

    delete(api_volume_mapping_url(nil, 999_999))

    expect(response).to have_http_status(:not_found)
  end

  context "GET /api/volume_mappings/:id" do
    it "returns one volume_mapping" do
      volume_mapping = FactoryBot.create(:volume_mapping)
      api_basic_authorize('volume_mapping_show')

      get(api_volume_mapping_url(nil, volume_mapping))

      expected = {
        "href" => api_volume_mapping_url(nil, volume_mapping)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Volume Mapping refresh action" do
    context "with an invalid id" do
      it "it responds with 404 Not Found" do
        api_basic_authorize(action_identifier(:volume_mappings, :refresh, :resource_actions, :post))

        post(api_volume_mapping_url(nil, 999_999), :params => gen_request(:refresh))

        expect(response).to have_http_status(:not_found)
      end
    end

    context "without an appropriate role" do
      it "it responds with 403 Forbidden" do
        volume_mapping = FactoryBot.create(:volume_mapping)
        api_basic_authorize

        post(api_volume_mapping_url(nil, volume_mapping), :params => gen_request(:refresh))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an appropriate role" do
      it "rejects refresh for unspecified volume mapping" do
        api_basic_authorize(action_identifier(:volume_mappings, :refresh, :resource_actions, :post))

        post(api_volume_mappings_url, :params => gen_request(:refresh, [{"href" => "/api/volume_mappings/"}, {"href" => "/api/volume_mappings/"}]))

        expect_bad_request(/Must specify an id/i)
      end

      it "refresh of a single Volume Mapping" do
        volume_mapping = FactoryBot.create(:volume_mapping)
        api_basic_authorize('volume_mapping_refresh')

        post(api_volume_mapping_url(nil, volume_mapping), :params => gen_request(:refresh))

        expect_single_action_result(:success => true, :message => /#{volume_mapping.id}.* refreshing/i, :href => api_volume_mapping_url(nil, volume_mapping))
      end

      it "refresh of multiple Host Initiators" do
        volume_mapping = FactoryBot.create(:volume_mapping)
        volume_mapping_two = FactoryBot.create(:volume_mapping)
        api_basic_authorize('volume_mapping_refresh')

        post(api_volume_mappings_url, :params => gen_request(:refresh, [{"href" => api_volume_mapping_url(nil, volume_mapping)}, {"href" => api_volume_mapping_url(nil, volume_mapping_two)}]))

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(
              "message" => a_string_matching(/#{volume_mapping.id}.* refreshing/i),
              "success" => true,
              "href"    => api_volume_mapping_url(nil, volume_mapping)
            ),
            a_hash_including(
              "message" => a_string_matching(/#{volume_mapping_two.id}.* refreshing/i),
              "success" => true,
              "href"    => api_volume_mapping_url(nil, volume_mapping_two)
            )
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
