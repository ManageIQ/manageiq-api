describe "Physical Storages API" do
  context "GET /api/physical_storages" do
    it "returns all physical_storages" do
      physical_storage = FactoryGirl.create(:physical_storage)
      api_basic_authorize('physical_storage_show_list')

      get(api_physical_storages_url)

      expected = {
        "name"      => "physical_storages",
        "resources" => [{"href" => api_physical_storage_url(nil, physical_storage)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/physical_storages/:id" do
    it "returns one physical_storage" do
      physical_storage = FactoryGirl.create(:physical_storage)
      api_basic_authorize('physical_storage_show')

      get(api_physical_storage_url(nil, physical_storage))

      expected = {
        "name" => physical_storage.name,
        "href" => api_physical_storage_url(nil, physical_storage)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Physical Storages refresh action" do
    context "with an invalid id" do
      it "it responds with 404 Not Found" do
        api_basic_authorize(action_identifier(:physical_storages, :refresh, :resource_actions, :post))

        post(api_physical_storage_url(nil, 999_999), :params => gen_request(:refresh))

        expect(response).to have_http_status(:not_found)
      end
    end

    context "without an appropriate role" do
      it "it responds with 403 Forbidden" do
        physical_storage = FactoryGirl.create(:physical_storage)
        api_basic_authorize

        post(api_physical_storage_url(nil, physical_storage), :params => gen_request(:refresh))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an appropriate role" do
      it "rejects refresh for unspecified physical storage" do
        api_basic_authorize(action_identifier(:physical_storages, :refresh, :resource_actions, :post))

        post(api_physical_storages_url, :params => gen_request(:refresh, [{"href" => "/api/physical_storages/"}, {"href" => "/api/physical_storages/"}]))

        expect_bad_request(/Must specify an id/i)
      end

      it "refresh of a single Physical Storage" do
        physical_storage = FactoryGirl.create(:physical_storage)
        api_basic_authorize('physical_storage_refresh')

        post(api_physical_storage_url(nil, physical_storage), :params => gen_request(:refresh))

        expect_single_action_result(:success => true, :message => /#{physical_storage.id}.* refreshing/i, :href => api_physical_storage_url(nil, physical_storage))
      end

      it "refresh of multiple Physical Storages" do
        physical_storage = FactoryGirl.create(:physical_storage)
        physical_storage_two = FactoryGirl.create(:physical_storage)
        api_basic_authorize('physical_storage_refresh')

        post(api_physical_storages_url, :params => gen_request(:refresh, [{"href" => api_physical_storage_url(nil, physical_storage)}, {"href" => api_physical_storage_url(nil, physical_storage_two)}]))

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(
              "message" => a_string_matching(/#{physical_storage.id}.* refreshing/i),
              "success" => true,
              "href"    => api_physical_storage_url(nil, physical_storage)
            ),
            a_hash_including(
              "message" => a_string_matching(/#{physical_storage_two.id}.* refreshing/i),
              "success" => true,
              "href"    => api_physical_storage_url(nil, physical_storage_two)
            )
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context 'Physical Racks subcollection' do
    let(:physical_rack) { FactoryGirl.create(:physical_rack) }
    let(:physical_storage) { FactoryGirl.create(:physical_storage, :physical_rack_id => physical_rack.id) }

    context 'GET /api/physical_storages/:id/physical_racks' do
      it 'returns the physical racks with an appropriate role' do
        api_basic_authorize(collection_action_identifier(:physical_racks, :read, :get))

        url_get = api_physical_storage_physical_racks_url(nil, physical_storage)
        url_resource = api_physical_storage_physical_rack_url(nil, physical_storage, physical_rack)

        expected = {
          'resources' => [{'href' => url_resource}]
        }
        get(url_get)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it 'does not return the physical racks without an appropriate role' do
        api_basic_authorize

        get(api_physical_storage_physical_rack_url(nil, physical_storage, physical_rack))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'GET /api/physical_storages/:id/physical_racks/:s_id' do
      it 'returns the physical rack with an appropriate role' do
        api_basic_authorize action_identifier(:physical_racks, :read, :resource_actions, :get)

        get(api_physical_storage_physical_rack_url(nil, physical_storage, physical_rack))

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('id' => physical_rack.id.to_s)
      end

      it 'does not return the physical rack without an appropriate role' do
        api_basic_authorize

        get(api_physical_storage_physical_rack_url(nil, physical_storage, physical_rack))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context 'Physical Chassis subcollection' do
    let(:physical_chassis) { FactoryGirl.create(:physical_chassis) }
    let(:physical_storage) { FactoryGirl.create(:physical_storage, :physical_chassis_id => physical_chassis.id) }

    context 'GET /api/physical_storages/:id/physical_chassis' do
      it 'returns the physical chassis with an appropriate role' do
        api_basic_authorize(collection_action_identifier(:physical_chassis, :read, :get))

        url_get = api_physical_storage_physical_chassis_url(nil, physical_storage)
        url_resource = api_physical_storage_one_physical_chassis_url(nil, physical_storage, physical_chassis)

        expected = {
          'resources' => [{'href' => url_resource}]
        }
        get(url_get)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it 'does not return the physical chassis without an appropriate role' do
        api_basic_authorize

        get(api_physical_storage_one_physical_chassis_url(nil, physical_storage, physical_chassis))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'GET /api/physical_storages/:id/physical_chassis/:s_id' do
      it 'returns the physical chassis with an appropriate role' do
        api_basic_authorize action_identifier(:physical_chassis, :read, :resource_actions, :get)

        get(api_physical_storage_one_physical_chassis_url(nil, physical_storage, physical_chassis))

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('id' => physical_chassis.id.to_s)
      end

      it 'does not return the physical chassis without an appropriate role' do
        api_basic_authorize

        get(api_physical_storage_one_physical_chassis_url(nil, physical_storage, physical_chassis))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
