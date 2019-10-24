describe "Enterprises API" do
  context "GET /api/enterprises" do
    before do
      @enterprise = MiqEnterprise.first
    end

    it "does not allow an unauthorized user to list the enterprises" do
      api_basic_authorize

      get(api_enterprises_url)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns the enterprises" do
      api_basic_authorize(:ems_infra)

      get(api_enterprises_url)

      expected = {
        "name"      => "enterprises",
        "resources" => [{"href" => api_enterprise_url(nil, @enterprise)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/enterprises/:id" do
    it "returns the enterprise" do
      enterprise = FactoryBot.create(:miq_enterprise)
      api_basic_authorize(:ems_infra)

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
