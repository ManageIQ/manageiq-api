RSpec.describe 'NetworkPorts API' do
  let(:ems) { FactoryGirl.create(:ems_network) }

  describe 'GET /api/network_ports' do
    it 'lists all network ports with an appropriate role' do
      network_port = FactoryGirl.create(:network_port)
      api_basic_authorize collection_action_identifier(:network_ports, :read, :get)
      get(api_network_ports_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'network_ports',
        'resources' => [
          hash_including('href' => api_network_port_url(nil, network_port))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids access to network ports without an appropriate role' do
      api_basic_authorize

      get(api_network_ports_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/network_ports/:id' do
    it 'will show a network port with an appropriate role' do
      network_port = FactoryGirl.create(:network_port)
      api_basic_authorize action_identifier(:network_ports, :read, :resource_actions, :get)

      get(api_network_port_url(nil, network_port))

      expect(response.parsed_body).to include('href' => api_network_port_url(nil, network_port))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to a network port without an appropriate role' do
      network_port = FactoryGirl.create(:network_port)
      api_basic_authorize

      get(api_network_port_url(nil, network_port))

      expect(response).to have_http_status(:forbidden)
    end
  end
end
