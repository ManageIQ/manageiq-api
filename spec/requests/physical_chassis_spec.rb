describe "Physical Chassis API" do
  context "GET /api/physical_chassis" do
    it "returns all physical_chassis" do
      physical_chassis = FactoryGirl.create(:physical_chassis)
      api_basic_authorize('physical_chassis_show_list')

      get(api_physical_chassis_url)

      expected = {
        "name"      => "physical_chassis",
        "resources" => [{"href" => api_one_physical_chassis_url(nil, physical_chassis)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/physical_chassis/:id" do
    it "returns one physical_chassis" do
      physical_chassis = FactoryGirl.create(:physical_chassis)
      api_basic_authorize('physical_chassis_show')

      get(api_one_physical_chassis_url(nil, physical_chassis))

      expected = {
        "name" => physical_chassis.name,
        "href" => api_one_physical_chassis_url(nil, physical_chassis)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Physical Chassis refresh action" do
    context "with an invalid id" do
      it "it responds with 404 Not Found" do
        api_basic_authorize(action_identifier(:physical_chassis, :refresh, :resource_actions, :post))

        post(api_one_physical_chassis_url(nil, 999_999), :params => gen_request(:refresh))

        expect(response).to have_http_status(:not_found)
      end
    end

    context "without an appropriate role" do
      it "it responds with 403 Forbidden" do
        physical_chassis = FactoryGirl.create(:physical_chassis)
        api_basic_authorize

        post(api_one_physical_chassis_url(nil, physical_chassis), :params => gen_request(:refresh))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an appropriate role" do
      it "rejects refresh for unspecified physical chassis" do
        api_basic_authorize(action_identifier(:physical_chassis, :refresh, :resource_actions, :post))

        post(api_physical_chassis_url, :params => gen_request(:refresh, [{"href" => "/api/physical_chassis/"}, {"href" => "/api/physical_chassis/"}]))

        expect_bad_request(/Must specify an id/i)
      end

      it "refresh of a single Physical Chassis" do
        physical_chassis = FactoryGirl.create(:physical_chassis)
        api_basic_authorize('physical_chassis_refresh')

        post(api_one_physical_chassis_url(nil, physical_chassis), :params => gen_request(:refresh))

        expect_single_action_result(:success => true, :message => /#{physical_chassis.id}.* refreshing/i, :href => api_one_physical_chassis_url(nil, physical_chassis))
      end

      it "refresh of multiple Physical Chassis" do
        physical_chassis = FactoryGirl.create(:physical_chassis)
        physical_chassis_two = FactoryGirl.create(:physical_chassis)
        api_basic_authorize('physical_chassis_refresh')

        post(api_physical_chassis_url, :params => gen_request(:refresh, [{"href" => api_one_physical_chassis_url(nil, physical_chassis)}, {"href" => api_one_physical_chassis_url(nil, physical_chassis_two)}]))

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(
              "message" => a_string_matching(/#{physical_chassis.id}.* refreshing/i),
              "success" => true,
              "href"    => api_one_physical_chassis_url(nil, physical_chassis)
            ),
            a_hash_including(
              "message" => a_string_matching(/#{physical_chassis_two.id}.* refreshing/i),
              "success" => true,
              "href"    => api_one_physical_chassis_url(nil, physical_chassis_two)
            )
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Subcollections" do
    let(:physical_chassis) { FactoryGirl.create(:physical_chassis) }
    let(:event_stream) { FactoryGirl.create(:event_stream, :physical_chassis_id => physical_chassis.id, :event_type => "Some Event") }

    context 'Events subcollection' do
      context 'GET /api/physical_chassis/:id/event_streams' do
        it 'returns the event_streams with an appropriate role' do
          api_basic_authorize(collection_action_identifier(:event_streams, :read, :get))

          expected = {
            'resources' => [
              { 'href' => api_one_physical_chassis_event_stream_url(nil, physical_chassis, event_stream) }
            ]
          }
          get(api_one_physical_chassis_event_streams_url(nil, physical_chassis))

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(expected)
        end

        it 'does not return the event_streams without an appropriate role' do
          api_basic_authorize
          get(api_one_physical_chassis_event_streams_url(nil, physical_chassis))

          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'GET /api/physical_chassis/:id/event_streams/:id' do
        it 'returns the event_stream with an appropriate role' do
          api_basic_authorize(action_identifier(:event_streams, :read, :resource_actions, :get))
          url = api_one_physical_chassis_event_stream_url(nil, physical_chassis, event_stream)
          expected = { 'href' => url }
          get(url)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(expected)
        end

        it 'does not return the event_stream without an appropriate role' do
          api_basic_authorize
          get(api_one_physical_chassis_event_stream_url(nil, physical_chassis, event_stream))

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
