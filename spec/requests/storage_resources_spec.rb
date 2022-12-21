describe "Storage Resources API" do
  fcontext "GET /api/storage_resources" do
    it "returns all storage_resources" do
      storage_resource = FactoryBot.create(:storage_resource)
      api_basic_authorize('storage_resource_show_list')

      get(api_storage_resources_url)

      expected = {
        "name"      => "storage_resources",
        "resources" => [{"href" => api_storage_resource_url(nil, storage_resource)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/storage_resources/:id" do
    it "returns one storage_resource" do
      storage_resource = FactoryBot.create(:storage_resources)
      api_basic_authorize('storage_resource_show')

      get(api_storage_resource_url(nil, storage_resource))

      expected = {
        "name" => storage_resource.name,
        "href" => api_storage_resource_url(nil, storage_resource)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
