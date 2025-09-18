RSpec.describe 'Cloud Networks API' do
  include Spec::Support::SupportsHelper

  context 'cloud networks index' do
    it 'rejects request without appropriate role' do
      api_basic_authorize

      get api_cloud_networks_url

      expect(response).to have_http_status(:forbidden)
    end

    it 'can list cloud networks' do
      FactoryBot.create_list(:cloud_network, 2)
      api_basic_authorize collection_action_identifier(:cloud_networks, :read, :get)

      get api_cloud_networks_url

      expect_query_result(:cloud_networks, 2)
      expect(response).to have_http_status(:ok)
    end
  end

  context 'Providers cloud_networks subcollection' do
    let(:provider) { FactoryBot.create(:ems_cloud).tap { |x| 2.times { x.cloud_networks << FactoryBot.create(:cloud_network) } } }

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
      FactoryBot.create(:ems_container) # Openshift container manager does not respond to #cloud_networks

      ems_cloud = FactoryBot.create(:ems_cloud) # Provider with cloud networks
      cloud_network_1 = FactoryBot.create(:cloud_network, :ext_management_system => ems_cloud.network_manager)
      cloud_network_2 = FactoryBot.create(:cloud_network, :ext_management_system => ems_cloud.network_manager)
      api_basic_authorize collection_action_identifier(:providers, :read, :get)
      get api_providers_url, :params => { :expand => 'resources,cloud_networks' }

      expected = {
        'resources' => a_collection_including(
          a_hash_including(
            'type'           => 'ManageIQ::Providers::Amazon::CloudManager',
            'cloud_networks' => a_collection_including(
              a_hash_including('id' => cloud_network_1.id.to_s),
              a_hash_including('id' => cloud_network_2.id.to_s)
            )
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
      openshift = FactoryBot.create(:ems_openshift)
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

    describe "POST /api/providers/:ems_id/cloud_networks" do
      let(:ems_network) { FactoryBot.create(:ems_network) }

      it "queues creation of the cloud network" do
        api_basic_authorize subcollection_action_identifier(:providers, :cloud_networks, :create)
        post api_provider_cloud_networks_url(nil, ems_network), :params => {:name => "new cloud network"}

        expected = {
          "results" => [
            a_hash_including(
              "success"   => true,
              "message"   => "Creating cloud network",
              "task_id"   => anything,
              "task_href" => a_string_matching(api_tasks_url)
            )
          ]
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)

        queue_item = MiqQueue.find_by(:class_name => ems_network.class.name, :method_name => "create_cloud_network")
        expect(queue_item).to have_attributes(
          :zone       => ems_network.zone_name,
          :queue_name => ems_network.queue_name_for_ems_operations
        )
      end
    end
  end

  describe 'OPTIONS /api/cloud_networks' do
    it 'returns a DDF schema for add when available via OPTIONS' do
      zone = FactoryBot.create(:zone, :name => "api_zone")
      provider = FactoryBot.create(:ems_network, :zone => zone)

      stub_supports(provider.class::CloudNetwork, :create)
      stub_params_for(provider.class::CloudNetwork, :create, :fields => [])

      options(api_cloud_networks_url(:ems_id => provider.id))

      expect(response.parsed_body['data']).to match("form_schema" => {"fields" => []})
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'OPTIONS /api/cloud_networks/:id' do
    it 'returns a DDF schema for edit when available via OPTIONS' do
      provider = FactoryBot.create(:ems_cloud).tap { |x| 2.times { x.cloud_networks << FactoryBot.create(:cloud_network) } }

      cloud_network = provider.cloud_networks.first
      stub_supports(cloud_network.class, :update)
      stub_params_for(cloud_network.class, :update, :fields => [])

      options(api_cloud_network_url(nil, cloud_network))
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data']).to include("form_schema" => {"fields" => []})
    end
  end
end
