describe "Host Initiators API" do
  context "POST /api/host_initiators" do
    it "with an invalid ems_id it responds with 404 Not Found" do
      api_basic_authorize(collection_action_identifier(:host_initiators, :create))

      request = {
        "action"   => "create",
        "resource" => {
          "ems_id"              => nil,
          "name"                => "test_host_initiator",
          "physical_storage_id" => "1",
          "port_type"           => "ISCSI",
          "iqn"                 => "test_iqn",
          "chap_name"           => "test_chap_name",
          "chap_secret"         => "test_chap_secret",
        }
      }

      post(api_host_initiators_url, :params => request)

      expect(response).to have_http_status(:bad_request)
    end

    it "creates new Host Initiator" do
      api_basic_authorize(collection_action_identifier(:host_initiators, :create))
      provider = FactoryBot.create(:ems_autosde, :name => 'Autosde')
      request = {
        "action"   => "create",
        "resource" => {
          "ems_id"              => provider.id,
          "name"                => "test_host_initiator",
          "physical_storage_id" => "1",
          "port_type"           => "ISCSI",
          "iqn"                 => "test_iqn",
          "chap_name"           => "test_chap_name",
          "chap_secret"         => "test_chap_secret",
        }
      }

      post(api_host_initiators_url, :params => request)

      expect_multiple_action_result(1, :success => true, :message => "Creating Host Initiator test_host_initiator for Provider: #{provider.name}", :task => true)
    end
  end

  context "GET /api/host_initiators" do
    it "returns all host_initiators" do
      host_initiator = FactoryBot.create(:host_initiator)
      api_basic_authorize('host_initiator_show_list')

      get(api_host_initiators_url)

      expected = {
        "name"      => "host_initiators",
        "resources" => [{"href" => api_host_initiator_url(nil, host_initiator)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/host_initiators/:id" do
    it "returns one host_initiator" do
      host_initiator = FactoryBot.create(:host_initiator)
      api_basic_authorize('host_initiator_show')

      get(api_host_initiator_url(nil, host_initiator))

      expected = {
        "name" => host_initiator.name,
        "href" => api_host_initiator_url(nil, host_initiator)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Host Initiators refresh action" do
    context "with an invalid id" do
      it "it responds with 404 Not Found" do
        api_basic_authorize(action_identifier(:host_initiators, :refresh, :resource_actions, :post))

        post(api_host_initiator_url(nil, 999_999), :params => gen_request(:refresh))

        expect(response).to have_http_status(:not_found)
      end
    end

    context "without an appropriate role" do
      it "it responds with 403 Forbidden" do
        host_initiator = FactoryBot.create(:host_initiator)
        api_basic_authorize

        post(api_host_initiator_url(nil, host_initiator), :params => gen_request(:refresh))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an appropriate role" do
      it "rejects refresh for unspecified host initiator" do
        api_basic_authorize(action_identifier(:host_initiators, :refresh, :resource_actions, :post))

        post(api_host_initiators_url, :params => gen_request(:refresh, [{"href" => "/api/host_initiators/"}, {"href" => "/api/host_initiators/"}]))

        expect_bad_request(/Must specify an id/i)
      end

      it "refresh of a single Host Initiator" do
        host_initiator = FactoryBot.create(:host_initiator)
        api_basic_authorize('host_initiator_refresh')

        post(api_host_initiator_url(nil, host_initiator), :params => gen_request(:refresh))

        expect_single_action_result(:success => true, :message => /#{host_initiator.id}.* refreshing/i, :href => api_host_initiator_url(nil, host_initiator))
      end

      it "refresh of multiple Host Initiators" do
        host_initiator = FactoryBot.create(:host_initiator)
        host_initiator_two = FactoryBot.create(:host_initiator)
        api_basic_authorize('host_initiator_refresh')

        post(api_host_initiators_url, :params => gen_request(:refresh, [{"href" => api_host_initiator_url(nil, host_initiator)}, {"href" => api_host_initiator_url(nil, host_initiator_two)}]))

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(
              "message" => a_string_matching(/#{host_initiator.id}.* refreshing/i),
              "success" => true,
              "href"    => api_host_initiator_url(nil, host_initiator)
            ),
            a_hash_including(
              "message" => a_string_matching(/#{host_initiator_two.id}.* refreshing/i),
              "success" => true,
              "href"    => api_host_initiator_url(nil, host_initiator_two)
            )
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
