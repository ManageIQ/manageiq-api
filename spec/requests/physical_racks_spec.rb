describe "Physical Racks API" do
  context "GET /api/physical_racks" do
    it "returns all Physical Racks" do
      physical_rack = FactoryGirl.create(:physical_rack)
      api_basic_authorize('physical_rack_show_list')

      get(api_physical_racks_url)

      expected = {
        "name"      => "physical_racks",
        "resources" => [{"href" => api_physical_rack_url(nil, physical_rack)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/physical_racks/:id" do
    it "returns a single Physical Rack" do
      physical_rack = FactoryGirl.create(:physical_rack)
      api_basic_authorize('physical_rack_show')

      get(api_physical_rack_url(nil, physical_rack))

      expected = {
        "name" => physical_rack.name,
        "href" => api_physical_rack_url(nil, physical_rack)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Physical Racks refresh action" do
    context "with an invalid id" do
      it "it responds with 404 Not Found" do
        api_basic_authorize(action_identifier(:physical_racks, :refresh, :resource_actions, :post))

        post(api_physical_rack_url(nil, 999_999), :params => gen_request(:refresh))

        expect(response).to have_http_status(:not_found)
      end
    end

    context "without an appropriate role" do
      it "it responds with 403 Forbidden" do
        physical_rack = FactoryGirl.create(:physical_rack)
        api_basic_authorize

        post(api_physical_rack_url(nil, physical_rack), :params => gen_request(:refresh))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an appropriate role" do
      it "rejects refresh for an unspecified Physical Rack" do
        api_basic_authorize(action_identifier(:physical_racks, :refresh, :resource_actions, :post))

        post(api_physical_racks_url, :params => gen_request(:refresh, [{"href" => api_physical_racks_url}, {"href" => api_physical_racks_url}]))

        expect_bad_request(/Must specify an id/i)
      end

      it "refresh of a single Physical Rack" do
        physical_rack = FactoryGirl.create(:physical_rack)
        api_basic_authorize('physical_rack_refresh')

        post(api_physical_rack_url(nil, physical_rack), :params => gen_request(:refresh))

        expect_single_action_result(:success => true, :message => /#{physical_rack.id}.* refreshing/i, :href => api_physical_rack_url(nil, physical_rack))
      end

      it "refresh of multiple Physical Racks" do
        first_physical_rack = FactoryGirl.create(:physical_rack)
        second_physical_rack = FactoryGirl.create(:physical_rack)
        api_basic_authorize('physical_rack_refresh')

        post(api_physical_racks_url, :params => gen_request(:refresh, [{"href" => api_physical_rack_url(nil, first_physical_rack)}, {"href" => api_physical_rack_url(nil, second_physical_rack)}]))

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(
              "message" => a_string_matching(/#{first_physical_rack.id}.* refreshing/i),
              "success" => true,
              "href"    => api_physical_rack_url(nil, first_physical_rack)
            ),
            a_hash_including(
              "message" => a_string_matching(/#{second_physical_rack.id}.* refreshing/i),
              "success" => true,
              "href"    => api_physical_rack_url(nil, second_physical_rack)
            )
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
