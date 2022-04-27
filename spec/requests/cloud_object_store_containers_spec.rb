describe "Cloud Object Store Containers API" do
  include Spec::Support::SupportsHelper

  context 'GET /api/cloud_object_store_containers' do
    it 'forbids access to cloud object store containers without an appropriate role' do
      api_basic_authorize

      get(api_cloud_object_store_containers_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns cloud object store containers with an appropriate role' do
      cloud_object_store_container = FactoryBot.create(:cloud_object_store_container)
      api_basic_authorize(collection_action_identifier(:cloud_object_store_containers, :read, :get))

      get(api_cloud_object_store_containers_url)

      expected = {
        'resources' => [{'href' => api_cloud_object_store_container_url(nil, cloud_object_store_container)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'GET /api/cloud_object_store_containers' do
    let(:cloud_object_store_container) { FactoryBot.create(:cloud_object_store_container) }

    it 'forbids access to a cloud object store container without an appropriate role' do
      api_basic_authorize

      get(api_cloud_object_store_container_url(nil, cloud_object_store_container))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the cloud object store container with an appropriate role' do
      api_basic_authorize(action_identifier(:cloud_object_store_containers, :read, :resource_actions, :get))

      get(api_cloud_object_store_container_url(nil, cloud_object_store_container))

      expected = {
        'href' => api_cloud_object_store_container_url(nil, cloud_object_store_container)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'POST /api/cloud_object_store_containers/' do
    it 'it can create cloud object store containers through POST' do
      zone = FactoryBot.create(:zone)
      provider = FactoryBot.create(:ems_storage, :zone => zone)
      cloud_tenant = FactoryBot.create(:cloud_tenant, :ext_management_system => provider)

      api_basic_authorize collection_action_identifier(:cloud_object_store_containers, :create, :post)
      submit_data = {
        :ems_id          => provider.id,
        :name            => 'foo',
        :cloud_tenant_id => cloud_tenant.id,
      }
      post(api_cloud_object_store_containers_url, :params => submit_data)

      expected = {
        'results' => a_collection_containing_exactly(
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Creating Cloud Object Store Container')
          )
        )
      }

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  context 'OPTIONS /api/cloud_object_store_containers' do
    it 'returns a DDF schema for add when available via OPTIONS' do
      zone = FactoryBot.create(:zone)
      provider = FactoryBot.create(:ems_storage, :zone => zone)
      stub_supports(provider.class::CloudObjectStoreContainer, :create)
      stub_params_for(provider.class::CloudObjectStoreContainer, :create, :fields => [])

      options(api_cloud_object_store_containers_url(nil, :ems_id => provider.id))

      expect(response.parsed_body['data']).to match("form_schema" => {"fields" => []})
      expect(response).to have_http_status(:ok)
    end
  end
end
