RSpec.describe "Cloud Templates API" do
  describe "as a subcollection of providers" do
    it "can list images of a provider" do
      api_basic_authorize(action_identifier(:cloud_templates, :read, :subcollection_actions, :get))
      ems = FactoryGirl.create(:ems_cloud)
      image = FactoryGirl.create(:template_cloud, :ext_management_system => ems)

      get(api_provider_cloud_templates_url(nil, ems))

      expected = {
        "count"     => 1,
        "name"      => "cloud_templates",
        "resources" => [
          {"href" => api_provider_cloud_template_url(nil, ems, image)}
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "will not list images unless authorized" do
      api_basic_authorize
      ems = FactoryGirl.create(:ems_cloud)
      FactoryGirl.create(:template_cloud, :ext_management_system => ems)

      get(api_provider_cloud_templates_url(nil, ems))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/providers/:c_id/cloud_templates/:id" do
    it "can show a provider's image" do
      api_basic_authorize(action_identifier(:cloud_templates, :read, :subresource_actions, :get))
      ems = FactoryGirl.create(:ems_cloud)
      image = FactoryGirl.create(:template_cloud, :ext_management_system => ems)

      get(api_provider_cloud_template_url(nil, ems, image))

      expected = {
        "href" => api_provider_cloud_template_url(nil, ems, image),
        "id"   => image.id.to_s
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "will not show an image unless authorized" do
      api_basic_authorize
      ems = FactoryGirl.create(:ems_cloud)
      image = FactoryGirl.create(:template_cloud, :ext_management_system => ems)

      get(api_provider_cloud_template_url(nil, ems, image))

      expect(response).to have_http_status(:forbidden)
    end
  end
end
