RSpec.describe "Event Streams" do
  describe "GET /api/event_streams" do
    around { |example| Timecop.freeze("2017-01-05 12:00 UTC") { example.run } }

    it "returns a list of event streams with the appropriate role" do
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      event_stream = FactoryBot.create(:miq_event)

      get(api_event_streams_url)

      expected = {"resources" => [{"href" => api_event_stream_url(nil, event_stream)}]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can filter by event type" do
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      start_event = FactoryBot.create(:miq_event, :event_type => "vm_start")
      _stop_event = FactoryBot.create(:miq_event, :event_type => "vm_stop")

      get(api_event_streams_url, :params => {:filter => ["event_type=vm_start"]})

      expected = {"resources" => [a_hash_including("href" => api_event_stream_url(nil, start_event))]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can filter by timestamp" do
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      _event1 = FactoryBot.create(:miq_event, :timestamp => 2.days.ago.end_of_day)
      event2 = FactoryBot.create(:miq_event, :timestamp => 1.day.ago.beginning_of_day)
      event3 = FactoryBot.create(:miq_event, :timestamp => 1.day.ago.end_of_day)
      _event4 = FactoryBot.create(:miq_event, :timestamp => Time.zone.today.beginning_of_day)

      get(api_event_streams_url, :params => {:filter => ["timestamp>2017-01-03", "timestamp<2017-01-05"]})

      expected = {
        "resources" => a_collection_containing_exactly(
          a_hash_including("href" => api_event_stream_url(nil, event2)),
          a_hash_including("href" => api_event_stream_url(nil, event3))
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can filter by target_type" do
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      vm = FactoryBot.create(:vm_vmware)
      host = FactoryBot.create(:host_vmware)
      vm_event = FactoryBot.create(:miq_event, :target => vm)
      _host_event = FactoryBot.create(:miq_event, :target => host)

      get(api_event_streams_url, :params => {:filter => ["target_type=VmOrTemplate"]})

      expected = {"resources" => [a_hash_including("href" => api_event_stream_url(nil, vm_event))]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can filter by target_id" do
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      vm1, vm2 = FactoryBot.create_list(:vm_vmware, 2)
      host = FactoryBot.create(:host_vmware)
      vm1_event = FactoryBot.create(:miq_event, :target => vm1)
      _vm2_event = FactoryBot.create(:miq_event, :target => vm2)
      _host_event = FactoryBot.create(:miq_event, :target => host)

      get(
        api_event_streams_url,
        :params => {
          :filter => [
            "target_id=#{vm1.id}",
            "target_type=VmOrTemplate"
          ]
        }
      )

      expected = {"resources" => [a_hash_including("href" => api_event_stream_url(nil, vm1_event))]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "limits the resources returned" do
      stub_settings_merge(:api => {:max_results_per_page => 2})
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      vm = FactoryBot.create(:vm_vmware)
      FactoryBot.create_list(:miq_event, 3, :target => vm, :timestamp => Time.zone.now)

      get(api_event_streams_url, :params => {:filter => ["target_type=VmOrTemplate", "timestamp>2017-01-01"]})

      expected = {
        "links"    => a_hash_including(
          "self" => a_string_matching("offset=0"),
          "next" => a_string_matching("offset=2")
        ),
        "count"    => 3,
        "subcount" => 2
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "will not authorize a request without the appropriate role" do
      api_basic_authorize

      get(api_event_streams_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/event_streams/:id" do
    it "returns the details of an event stream with the appropriate role" do
      api_basic_authorize(action_identifier(:event_streams, :read, :resource_actions, :get))
      event_stream = FactoryBot.create(:miq_event, :message => "I'm an event stream!")

      get(api_event_stream_url(nil, event_stream))

      expect(response.parsed_body).to include("message" => "I'm an event stream!")
      expect(response).to have_http_status(:ok)
    end

    it "will not authorize a request without the appropriate role" do
      api_basic_authorize
      event_stream = FactoryBot.create(:miq_event)

      get(api_event_stream_url(nil, event_stream))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/event_streams with query action" do
    it "returns the details of the requested event streams with the appropriate role" do
      api_basic_authorize(action_identifier(:event_streams, :query, :collection_actions, :post))
      event_stream = FactoryBot.create(:miq_event, :message => "I'm an event stream!")

      post(
        api_event_streams_url,
        :params => {
          :action    => "query",
          :resources => [{"href" => api_event_stream_url(nil, event_stream)}]
        }
      )

      expect(response).to have_http_status(:ok)
    end

    it "will not authorize a request without the appropriate role" do
      api_basic_authorize
      event_stream = FactoryBot.create(:miq_event)

      post(
        api_event_streams_url,
        :params => {
          :action    => "query",
          :resources => [{"href" => api_event_stream_url(nil, event_stream)}]
        }
      )

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'OPTIONS /api/event_streams' do
    it 'returns expected and additional attributes' do
      MiqEventDefinitionSet.seed
      options(api_event_streams_url)

      expect_options_results(:event_streams)

      body = response.parsed_body
      expect(body["data"].keys).to eq(["timeline_events"])
      expect(body["data"]["timeline_events"].keys.sort).to eq(%w[EmsEvent MiqEvent])
      expect(body["data"]["timeline_events"]["EmsEvent"].keys.sort).to eq(%w[description group_levels group_names])
      expect(body["data"]["timeline_events"]["EmsEvent"]["group_names"].keys.sort).to include("addition", "other")
      expect(body["data"]["timeline_events"]["EmsEvent"]["group_levels"].keys.sort).to eq(%w[critical detail warning])

      expect(body["data"]["timeline_events"]["MiqEvent"].keys.sort).to eq(%w[description group_levels group_names])
      expect(body["data"]["timeline_events"]["MiqEvent"]["group_names"].keys.sort).to include("auth_validation", "other")
      expect(body["data"]["timeline_events"]["MiqEvent"]["group_levels"].keys.sort).to eq(%w[detail failure success])
    end
  end
end
