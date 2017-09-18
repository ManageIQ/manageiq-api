RSpec.describe 'Cloud Networks API' do
  context 'cloud networks index' do
    it 'rejects request without appropriate role' do
      api_basic_authorize

      get api_cloud_networks_url

      expect(response).to have_http_status(:forbidden)
    end

    it 'can list cloud networks' do
      FactoryGirl.create_list(:cloud_network, 2)
      api_basic_authorize collection_action_identifier(:cloud_networks, :read, :get)

      get api_cloud_networks_url

      expect_query_result(:cloud_networks, 2)
      expect(response).to have_http_status(:ok)
    end
  end

  context 'Providers cloud_networks subcollection' do
    let(:provider) { FactoryGirl.create(:ems_amazon_with_cloud_networks) }

    it 'queries Providers cloud_networks' do
      cloud_network_ids = provider.cloud_networks.pluck(:id)
      api_basic_authorize subcollection_action_identifier(:providers, :cloud_networks, :read, :get)

      get api_provider_cloud_networks_url(nil, provider), :params => { :expand => 'resources' }

      expect_query_result(:cloud_networks, 2)
      expect_result_resources_to_include_data('resources', 'id' => cloud_network_ids.collect(&:to_s))
    end

    it "will not list cloud networks of a provider without the appropriate role" do
      api_basic_authorize

      get api_provider_cloud_networks_url(nil, provider)

      expect(response).to have_http_status(:forbidden)
    end

    it 'queries individual provider cloud_network' do
      api_basic_authorize(action_identifier(:cloud_networks, :read, :subresource_actions, :get))
      network = provider.cloud_networks.first

      get(api_provider_cloud_network_url(nil, provider, network))

      expect_single_resource_query('name' => network.name, 'id' => network.id.to_s, 'ems_ref' => network.ems_ref)
    end

    it "will not show the cloud network of a provider without the appropriate role" do
      api_basic_authorize
      network = provider.cloud_networks.first

      get(api_provider_cloud_network_url(nil, provider, network))

      expect(response).to have_http_status(:forbidden)
    end

    it 'successfully returns providers on query when providers do not have cloud_networks attribute' do
      FactoryGirl.create(:ems_openshift) # Openshift does not respond to #cloud_networks
      FactoryGirl.create(:ems_amazon_with_cloud_networks) # Provider with cloud networks
      api_basic_authorize collection_action_identifier(:providers, :read, :get)

      get api_providers_url, :params => { :expand => 'resources,cloud_networks' }

      expected = {
        'resources' => a_collection_including(
          a_hash_including(
            'type'           => 'ManageIQ::Providers::Amazon::CloudManager',
            'cloud_networks' => a_collection_including
          ),
          a_hash_including(
            'type' => 'ManageIQ::Providers::Openshift::ContainerManager'
          )
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'returns empty resources array when querying on a provider with no cloud_networks attribute' do
      openshift = FactoryGirl.create(:ems_openshift)
      api_basic_authorize subcollection_action_identifier(:providers, :cloud_networks, :read, :get)

      get(api_provider_cloud_networks_url(nil, openshift), :params => { :expand => 'resources' })

      expected = {
        'name'      => 'cloud_networks',
        'count'     => 0,
        'subcount'  => 0,
        'resources' => []
      }

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end
end
