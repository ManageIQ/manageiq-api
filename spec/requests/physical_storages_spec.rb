describe "Physical Storages API" do
  context "POST /api/physical_storages" do
    it "creates new storage" do
      api_basic_authorize(collection_action_identifier(:physical_storages, :create))
      provider = FactoryBot.create(:ems_autosde, :name => 'Autosde')
      request = {
        "action"   => "create",
        "resource" => {
          "ems_id"                     => provider.id,
          "name"                       => "test_storage",
          "physical_storage_family_id" => "1",
          "management_ip"              => "1.1.1.1",
          "user"                       => "user",
          "password"                   => "password"
        }
      }

      post(api_physical_storages_url, :params => request)

      expect_multiple_action_result(1, :success => true, :message => "Creating Physical Storage test_storage for Provider: #{provider.name}", :task => true)
    end
  end

  context "Physical Storages delete action" do
    it "with an invalid id" do
      api_basic_authorize(action_identifier(:physical_storages, :delete, :resource_actions, :post))

      post(api_physical_storage_url(nil, 999_999), :params => gen_request(:delete))

      expect(response).to have_http_status(:not_found)
    end

    it "rejects Delete for unsupported physical storage" do
      physical_storage = FactoryBot.create(:physical_storage, :name => 'test_storage')
      api_basic_authorize('physical_storage_delete')

      post(api_physical_storage_url(nil, physical_storage), :params => gen_request(:delete))

      expect_bad_request(/Feature not available/i)
    end

    it "Deletion of a single Physical Storage" do
      provider = FactoryBot.create(:ems_autosde, :name => 'Autosde')
      physical_storage = FactoryBot.create("ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage", :name => 'test_storage', :ext_management_system => provider)
      api_basic_authorize('physical_storage_delete')

      post(api_physical_storage_url(nil, physical_storage), :params => gen_request(:delete))

      expect_single_action_result(:success => true, :message => /Detaching Physical Storage id: #{physical_storage.id}/)
    end

    it "Delete of multiple Physical Storages" do
      provider = FactoryBot.create(:ems_autosde, :name => 'Autosde')
      physical_storage = FactoryBot.create("ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage", :name => 'test_storage', :ext_management_system => provider)
      physical_storage_two = FactoryBot.create("ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage", :name => 'test_storage', :ext_management_system => provider)
      api_basic_authorize('physical_storage_delete')

      post(api_physical_storages_url, :params => gen_request(:delete, [{"href" => api_physical_storage_url(nil, physical_storage)}, {"href" => api_physical_storage_url(nil, physical_storage_two)}]))

      expected = {
        "results" => a_collection_containing_exactly(
          a_hash_including(
            "href"    => api_physical_storage_url(nil, physical_storage),
            "message" => a_string_matching(/Detaching Physical Storage id: #{physical_storage.id}/i),
            "success" => true
          ),
          a_hash_including(
            "href"    => api_physical_storage_url(nil, physical_storage_two),
            "message" => a_string_matching(/Detaching Physical Storage id: #{physical_storage_two.id}/i),
            "success" => true
          )
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  context "GET /api/physical_storages" do
    it "returns all physical_storages" do
      physical_storage = FactoryBot.create(:physical_storage)
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
      physical_storage = FactoryBot.create(:physical_storage)
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
        physical_storage = FactoryBot.create(:physical_storage)
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
        physical_storage = FactoryBot.create(:physical_storage)
        api_basic_authorize('physical_storage_refresh')

        post(api_physical_storage_url(nil, physical_storage), :params => gen_request(:refresh))

        expect_single_action_result(:success => true, :message => /#{physical_storage.id}.* refreshing/i, :href => api_physical_storage_url(nil, physical_storage))
      end

      it "refresh of multiple Physical Storages" do
        physical_storage = FactoryBot.create(:physical_storage)
        physical_storage_two = FactoryBot.create(:physical_storage)
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

  context 'Physical Storages edit action' do
    it "PUT /api/physical_storages/:id'" do
      provider = FactoryBot.create(:ems_autosde, :name => 'Autosde')
      physical_storage = FactoryBot.create("ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage", :ext_management_system => provider)

      api_basic_authorize('physical_storage_edit')
      put(api_physical_storage_url(nil, physical_storage))
      expect(response.parsed_body["message"]).to include("Updating")
      expect(response).to have_http_status(:ok)
    end
  end
end
