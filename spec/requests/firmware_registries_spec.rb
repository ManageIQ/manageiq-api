RSpec.describe "firmware_registries API" do
  let!(:registry) { FactoryBot.create(:firmware_registry) }
  let(:registry2) { FactoryBot.create(:firmware_registry) }

  describe 'GET /api/firmware_registries' do
    let(:url) { api_firmware_registries_url }

    it 'returns the firmware_registries with an appropriate role' do
      api_basic_authorize action_identifier(:firmware_registries, :read, :collection_actions, :get)
      get(url)
      expect_result_resources_to_include_hrefs(
        'resources',
        [
          api_firmware_registry_url(nil, registry)
        ]
      )
      expect(response).to have_http_status(:ok)
    end

    it 'does not return the firmware_registries without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/firmware_registries' do
    let(:url) { api_firmware_registries_url }

    context 'action: create' do
      let(:params) do
        {
          :type     => 'FirmwareRegistry::RestApiDepot',
          :name     => 'test-registry',
          :url      => 'http://my-registry.com:1234/images',
          :userid   => 'username',
          :password => 'password'
        }
      end

      it 'creates firmware registry with an appropriate role' do
        api_basic_authorize action_identifier(:firmware_registries, :create, :collection_actions, :post)
        post(url, :params => gen_request(:create, params))
        expect(response).to have_http_status(:ok)
        expect_single_action_result('name' => 'test-registry')
      end

      it 'does not create firmware_registries without an appropriate role' do
        api_basic_authorize
        post(url, :params => gen_request(:create, params))
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'action: delete' do
      it 'deletes single firmware registry with an appropriate role' do
        api_basic_authorize action_identifier(:firmware_registries, :delete, :collection_actions, :post)
        post(url, :params => gen_request(:delete, [{:id => registry.id}]))
        expect(FirmwareRegistry.count).to be_zero
        expect(response).to have_http_status(:ok)
      end

      it 'deletes multiple firmware registries with an appropriate role' do
        api_basic_authorize action_identifier(:firmware_registries, :delete, :collection_actions, :post)
        post(url, :params => gen_request(:delete, [{:id => registry.id}, {:id => registry2.id}]))
        expect(FirmwareRegistry.count).to be_zero
        expect(response).to have_http_status(:ok)
      end

      it 'does not create firmware_registries without an appropriate role' do
        api_basic_authorize
        post(url, :params => gen_request(:delete, []))
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'action: sync_fw_binaries' do
      it 'syncs firmware registry with an appropriate role' do
        api_basic_authorize action_identifier(:firmware_registries, :sync_fw_binaries, :collection_actions, :post)
        post(url, :params => gen_request(:sync_fw_binaries, [{:id => registry.id}]))
        expect(MiqQueue.count).to eq(1)
        expect(response).to have_http_status(:ok)
      end

      it 'syncs multiple firmware registries with an appropriate role' do
        api_basic_authorize action_identifier(:firmware_registries, :sync_fw_binaries, :collection_actions, :post)
        post(url, :params => gen_request(:sync_fw_binaries, [{:id => registry.id}, {:id => registry2.id}]))
        expect(MiqQueue.count).to eq(2)
        expect(response).to have_http_status(:ok)
      end

      it 'does not create firmware_registries without an appropriate role' do
        api_basic_authorize
        post(url, :params => gen_request(:sync_fw_binaries, []))
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /api/firmware_registries/:id' do
    let(:url) { api_firmware_registry_url(nil, registry) }

    it 'returns the firmware_registry with an appropriate role' do
      api_basic_authorize action_identifier(:firmware_registries, :read, :resource_actions, :get)
      get(url)
      expect_single_resource_query('href' => api_firmware_registry_url(nil, registry))
      expect(response).to have_http_status(:ok)
    end

    it 'does not return the firmware_registries without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/firmware_registries/:id' do
    let(:url) { api_firmware_registry_url(nil, registry) }

    it 'destroys firmware_registry with an appropriate role' do
      api_basic_authorize action_identifier(:firmware_registries, :read, :resource_actions, :get)
      expect(FirmwareRegistry.count).to eq(1)
      delete(url)
      expect(response).to have_http_status(:no_content)
      expect(FirmwareRegistry.count).to eq(0)
    end

    it 'does not destroy firmware_registry without an appropriate role' do
      api_basic_authorize
      delete(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/firmware_registries/:id' do
    let(:url) { api_firmware_registry_url(nil, registry) }

    context 'action: sync_fw_binaries' do
      let(:params) { gen_request(:sync_fw_binaries) }

      it 'triggers sync_fw_binaries with an appropriate role' do
        api_basic_authorize action_identifier(:firmware_registries, :sync_fw_binaries, :resource_actions, :post)
        expect(MiqQueue.count).to eq(0)
        post(url, :params => params)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['message']).to eq("FirmwareBinary [id: #{registry.id}] synced")
        expect(MiqQueue.count).to eq(1)
        expect(MiqQueue.first).to have_attributes(:instance_id => registry.id)
      end

      it 'does not trigger without an appropriate role' do
        api_basic_authorize
        post(url, :params => params)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
