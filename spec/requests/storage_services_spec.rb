describe "Storage Services API" do
  include Spec::Support::SupportsHelper

  let(:provider) { FactoryBot.create(:ems_autosde) }
  let(:storage_service_klass) { FactoryBot.build(:storage_service).class }

  context "GET /api/storage_services" do
    it "returns all storage_services" do
      storage_service = FactoryBot.create(:storage_service)
      api_basic_authorize('storage_service_show_list')

      get(api_storage_services_url)

      expected = {
        "name"      => "storage_services",
        "resources" => [{"href" => api_storage_service_url(nil, storage_service)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/storage_services/:id" do
    it "returns one storage_service" do
      storage_service = FactoryBot.create(:storage_services)
      api_basic_authorize('storage_service_show')

      get(api_storage_service_url(nil, storage_service))

      expected = {
        "name" => storage_service.name,
        "href" => api_storage_service_url(nil, storage_service)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "POST /api/storage_services" do
    it "creates new Storage Service" do
      api_basic_authorize(collection_action_identifier(:storage_services, :create))
      request = {
        "action"   => "create",
        "resource" => {
          "ems_id"      => provider.id,
          "name"        => "test_storage_service",
          "description" => "description of test_storage_service",
        }
      }
      stub_supports(storage_service_klass, :create)
      post(api_storage_services_url, :params => request)
      expect_multiple_action_result(1, :success => true, :message => /Creating Storage Service test_storage_service for Provider #{provider.name}/, :task => true)
    end
  end

  it "deletes a single Storage Service" do
    service = FactoryBot.create(:storage_service, :name => 'test_service', :ext_management_system => provider)
    api_basic_authorize('storage_service_delete')

    stub_supports(storage_service_klass, :delete)
    post(api_storage_service_url(nil, service), :params => gen_request(:delete))

    expect_single_action_result(:success => true, :message => /Deleting Storage Service id: #{service.id} name: '#{service.name}'/)
  end

  it "deletes multiple Storage Services" do
    service1 = FactoryBot.create(:storage_service, :name => 'test_service1', :ext_management_system => provider)
    service2 = FactoryBot.create(:storage_service, :name => 'test_service2', :ext_management_system => provider)
    api_basic_authorize('storage_service_delete')

    stub_supports(storage_service_klass, :delete)
    post(api_storage_services_url, :params => gen_request(:delete, [{"href" => api_storage_service_url(nil, service1)}, {"href" => api_storage_service_url(nil, service2)}]))

    results = response.parsed_body["results"]

    expect(results[0]["message"]).to match(/Deleting Storage Service id: #{service1.id} name: '#{service1.name}'/)
    expect(results[0]["success"]).to match(true)
    expect(results[1]["message"]).to match(/Deleting Storage Service id: #{service2.id} name: '#{service2.name}'/)
    expect(results[1]["success"]).to match(true)

    expect(response).to have_http_status(:ok)
  end

  context 'Storage Services edit action' do
    it "PUT /api/storage_services/:id'" do
      storage_service = FactoryBot.create(:storage_service, :ext_management_system => provider)

      api_basic_authorize('storage_service_edit')

      stub_supports(storage_service_klass, :update)
      put(api_storage_service_url(nil, storage_service))

      expect(response.parsed_body["message"]).to include("Updating")
      expect(response).to have_http_status(:ok)
    end
  end
end
