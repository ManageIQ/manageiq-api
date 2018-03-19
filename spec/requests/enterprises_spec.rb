describe "Enterprises API" do
  context "GET /api/enterprises" do
    it "returns the enterprises" do
      enterprise = FactoryGirl.create(:miq_enterprise)
      api_basic_authorize

      get(api_enterprises_url)

      expected = {
        "name"      => "enterprises",
        "resources" => [{"href" => api_enterprise_url(nil, enterprise)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/enterprises/:id" do
    it "returns the enterprise" do
      enterprise = FactoryGirl.create(:miq_enterprise)
      api_basic_authorize

      get(api_enterprise_url(nil, enterprise))

      expected = {
        "name" => enterprise.name,
        "href" => api_enterprise_url(nil, enterprise)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
