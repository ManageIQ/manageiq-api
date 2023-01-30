describe "Storage Service Resource Attachments API" do
  context "GET /api/storage_service_resource_attachments" do
    it "returns all storage_service_resource_attachments" do
      storage_service_resource_attachment = FactoryBot.create(:storage_service_resource_attachment)
      api_basic_authorize('storage_service_resource_attachment_show_list')

      get(api_storage_service_resource_attachments_url)

      expected = {
        "name"      => "storage_service_resource_attachments",
        "resources" => [{"href" => api_storage_service_resource_attachment_url(nil, storage_service_resource_attachment)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/storage_service_resource_attachments/:id" do
    it "returns one storage_service_resource_attachment" do
      storage_service_resource_attachment = FactoryBot.create(:storage_service_resource_attachments)
      api_basic_authorize('storage_service_resource_attachment_show')

      get(api_storage_service_resource_attachment_url(nil, storage_service_resource_attachment))
      expect(response).to have_http_status(:ok)

      expected = {
        "href" => api_storage_service_resource_attachment_url(nil, storage_service_resource_attachment)
      }
      expect(response.parsed_body).to include(expected)

      # assert response has required fields
      expected = %w[storage_service_id storage_resource_id]
      expect(expected - response.parsed_body.keys).to be_empty
    end
  end
end
