describe "Physical Storage Families API" do
  context "GET /api/physical_storage_families" do
    it "returns all physical_storage_families" do
      physical_storage_family = FactoryBot.create(:physical_storage_family)
      api_basic_authorize('physical_storage_family_show_list')

      get(api_physical_storage_families_url)

      expected = {
        "name"      => "physical_storage_families",
        "resources" => [{"href" => api_physical_storage_family_url(nil, physical_storage_family)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/physical_storage_families/:id" do
    it "returns one physical_storage_family" do
      physical_storage_family = FactoryBot.create(:physical_storage_family)
      api_basic_authorize('physical_storage_family_show')

      get(api_physical_storage_family_url(nil, physical_storage_family))

      expected = {
        "name" => physical_storage_family.name,
        "href" => api_physical_storage_family_url(nil, physical_storage_family)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
