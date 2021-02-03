RSpec.describe 'EventDefinitionSets API' do
  let(:event) { FactoryBot.create(:miq_event_definition, :name => "some_event") }
  let(:event_definition_set) { FactoryBot.create(:miq_event_definition_set, :name => 'event_definition_set', :events => [event]) }

  describe 'GET /api/event_definition_sets' do
    it 'does not list event definition sets without an appropriate role' do
      api_basic_authorize

      get(api_event_definition_sets_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'lists all event definition sets with an appropriate role' do
      api_basic_authorize collection_action_identifier(:event_definition_sets, :read, :get)
      event_definition_set_href = api_event_definition_set_url(nil, event_definition_set)

      get(api_event_definition_sets_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'event_definition_sets',
        'resources' => [
          hash_including('href' => event_definition_set_href)
        ]
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'GET /api/event_definition_sets/:id' do
    it 'does not let you query event definition sets without an appropriate role' do
      api_basic_authorize

      get(api_event_definition_set_url(nil, event_definition_set))

      expect(response).to have_http_status(:forbidden)
    end

    it 'can query an event definition set by its id' do
      api_basic_authorize action_identifier(:event_definition_sets, :read, :resource_actions, :get)

      get(api_event_definition_set_url(nil, event_definition_set))

      expected = {
        'id'   => event_definition_set.id.to_s,
        'name' => "event_definition_set"
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'GET /api/event_definition_sets/:id/events' do
    it 'can list all events in the event definition set ' do
      FactoryBot.create(:miq_event_definition, :name => "other_event")
      expected = {
        "count"     => 2,
        "name"      => "events",
        "subcount"  => 1,
        "resources" => [
          {"href" => api_event_definition_set_event_url(nil, event_definition_set, event)}
        ]
      }
      api_basic_authorize

      get(api_event_definition_set_events_url(nil, event_definition_set))

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end
end
