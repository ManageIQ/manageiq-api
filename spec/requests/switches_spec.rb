describe "Switches API" do
  context 'GET /api/switches' do
    it 'forbids access to switches without an appropriate role' do
      api_basic_authorize

      get(api_switches_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns switches with an appropriate role' do
      switch = FactoryGirl.create(:switch)
      api_basic_authorize(collection_action_identifier(:switches, :read, :get))

      get(api_switches_url)

      expected = {
        'resources' => [{'href' => api_switch_url(nil, switch)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'GET /api/switches' do
    let(:switch) { FactoryGirl.create(:switch) }

    it 'forbids access to a switch without an appropriate role' do
      api_basic_authorize

      get(api_switch_url(nil, switch))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the switch with an appropriate role' do
      api_basic_authorize(action_identifier(:switches, :read, :resource_actions, :get))

      get(api_switch_url(nil, switch))

      expected = {
        'href' => api_switch_url(nil, switch)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
