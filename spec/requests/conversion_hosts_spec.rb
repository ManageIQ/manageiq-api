describe "ConversionHosts API" do
  context "collections" do
    it 'lists all conversion hosts with an appropriate role' do
      conversion_host = FactoryGirl.create(:conversion_host)
      api_basic_authorize(collection_action_identifier(:conversion_hosts, :read, :get))
      get(api_conversion_hosts_url)

      expected = {
        'count'     => 1,
        'name'      => 'conversion_hosts',
        'resources' => [
          hash_including('href' => api_conversion_host_url(nil, conversion_host))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "resources" do
    it 'will show a conversion host with an appropriate role' do
      conversion_host = FactoryGirl.create(:conversion_host)
      api_basic_authorize(action_identifier(:conversion_hosts, :read, :resource_actions, :get))

      get(api_conversion_host_url(nil, conversion_host))

      expect(response.parsed_body).to include('href' => api_conversion_host_url(nil, conversion_host))
      expect(response).to have_http_status(:ok)
    end
  end

  context "access" do
    it "forbids access to conversion hosts without an appropriate role" do
      api_basic_authorize
      get(api_conversion_hosts_url)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids access to a conversion host resource without an appropriate role" do
      api_basic_authorize
      conversion_host = FactoryGirl.create(:conversion_host)
      get(api_conversion_host_url(nil, conversion_host))

      expect(response).to have_http_status(:forbidden)
    end
  end
end
