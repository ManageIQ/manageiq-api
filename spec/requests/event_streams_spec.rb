RSpec.describe "Event Streams" do
  describe "GET /api/event_streams" do
    around { |example| Timecop.freeze("2017-01-05 12:00 UTC") { example.run } }

    specify "target_type is a required filter" do
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      FactoryGirl.create(:miq_event)

      get(api_event_streams_url, :params => {:filter => ["timestamp>2017-01-01"]})

      expect(response.parsed_body).to include_error_with_message("Must specify target_type")
      expect(response).to have_http_status(:bad_request)
    end

    specify "event streams must be filtered by timestamp occurring after a certain date" do
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      FactoryGirl.create(:miq_event)

      get(api_event_streams_url, :params => {:filter => ["target_type=VmOrTemplate"]})

      expect(response.parsed_body).to include_error_with_message("Must specify a minimum value for timestamp")
      expect(response).to have_http_status(:bad_request)
    end

    it "will aggregate required filter messages" do
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      FactoryGirl.create(:miq_event)

      get(api_event_streams_url)

      expect(response.parsed_body).to include_error_with_message("Must specify target_type, must specify a minimum value for timestamp")
      expect(response).to have_http_status(:bad_request)
    end

    it "returns a list of event streams with the appropriate role" do
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      vm = FactoryGirl.create(:vm_vmware)
      event_stream = FactoryGirl.create(:miq_event, :target => vm, :timestamp => Time.zone.now)

      get(api_event_streams_url, :params => {:filter => ["target_type=VmOrTemplate", "timestamp>2017-01-01"]})

      expected = {"resources" => [{"href" => api_event_stream_url(nil, event_stream)}]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can filter by event type" do
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      vm = FactoryGirl.create(:vm_vmware)
      start_event = FactoryGirl.create(:miq_event, :target => vm, :timestamp => Time.zone.now, :event_type => "vm_start")
      _stop_event = FactoryGirl.create(:miq_event, :target => vm, :timestamp => Time.zone.now, :event_type => "vm_stop")

      get(
        api_event_streams_url,
        :params => {
          :filter => [
            "target_type=VmOrTemplate",
            "timestamp>2017-01-01",
            "event_type=vm_start"
          ]
        }
      )

      expected = {"resources" => [a_hash_including("href" => api_event_stream_url(nil, start_event))]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can filter by timestamp" do
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      vm = FactoryGirl.create(:vm_vmware)
      _event1 = FactoryGirl.create(:miq_event, :target => vm, :timestamp => 2.days.ago.end_of_day)
      event2 = FactoryGirl.create(:miq_event, :target => vm, :timestamp => 1.day.ago.beginning_of_day)
      event3 = FactoryGirl.create(:miq_event, :target => vm, :timestamp => 1.day.ago.end_of_day)
      _event4 = FactoryGirl.create(:miq_event, :target => vm, :timestamp => Time.zone.today.beginning_of_day)

      get(
        api_event_streams_url,
        :params => {
          :filter => [
            "target_type=VmOrTemplate",
            "timestamp>2017-01-03",
            "timestamp<2017-01-05"
          ]
        }
      )

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
      vm = FactoryGirl.create(:vm_vmware)
      host = FactoryGirl.create(:host_vmware)
      vm_event = FactoryGirl.create(:miq_event, :timestamp => Time.zone.now, :target => vm)
      _host_event = FactoryGirl.create(:miq_event, :timestamp => Time.zone.now, :target => host)

      get(
        api_event_streams_url,
        :params => {
          :filter => [
            "target_type=VmOrTemplate",
            "timestamp>2017-01-01"
          ]
        }
      )

      expected = {"resources" => [a_hash_including("href" => api_event_stream_url(nil, vm_event))]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can filter by target_id" do
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      vm1, vm2 = FactoryGirl.create_list(:vm_vmware, 2)
      host = FactoryGirl.create(:host_vmware)
      vm1_event = FactoryGirl.create(:miq_event, :timestamp => Time.zone.now, :target => vm1)
      _vm2_event = FactoryGirl.create(:miq_event, :timestamp => Time.zone.now, :target => vm2)
      _host_event = FactoryGirl.create(:miq_event, :timestamp => Time.zone.now, :target => host)

      get(
        api_event_streams_url,
        :params => {
          :filter => [
            "target_id=#{vm1.id}",
            "target_type=VmOrTemplate",
            "timestamp>2017-01-01"
          ]
        }
      )

      expected = {"resources" => [a_hash_including("href" => api_event_stream_url(nil, vm1_event))]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "limits the resources returned" do
      stub_settings_merge(:api => {:event_streams_default_limit => 2})
      api_basic_authorize(action_identifier(:event_streams, :read, :collection_actions, :get))
      vm = FactoryGirl.create(:vm_vmware)
      FactoryGirl.create_list(:miq_event, 3, :target => vm, :timestamp => Time.zone.now)

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
      event_stream = FactoryGirl.create(:miq_event, :message => "I'm an event stream!")

      get(api_event_stream_url(nil, event_stream))

      expect(response.parsed_body).to include("message" => "I'm an event stream!")
      expect(response).to have_http_status(:ok)
    end

    it "will not authorize a request without the appropriate role" do
      api_basic_authorize
      event_stream = FactoryGirl.create(:miq_event)

      get(api_event_stream_url(nil, event_stream))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/event_streams with query action" do
    it "returns the details of the requested event streams with the appropriate role" do
      api_basic_authorize(action_identifier(:event_streams, :query, :collection_actions, :post))
      event_stream = FactoryGirl.create(:miq_event, :message => "I'm an event stream!")

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
      event_stream = FactoryGirl.create(:miq_event)

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
end
