describe "Storage Services API" do
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
end
