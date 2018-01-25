RSpec.describe "Customization Scripts" do
  describe "display a config pattern's details" do
    context "without an appropriate role" do
      it "forbids access to read config pattern" do
        config_pattern = FactoryGirl.create(:customization_script)

        api_basic_authorize
        get api_customization_script_url(nil, config_pattern)

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end
    end

    context "with valid id" do
      it "returns both id and href" do
        config_pattern = FactoryGirl.create(:customization_script)

        api_basic_authorize action_identifier(:customization_scripts, :read, :resource_actions, :get)
        get api_customization_script_url(nil, config_pattern)

        expect_single_resource_query("id" => config_pattern.id.to_s, "href" => api_customization_script_url(nil, config_pattern))
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid id" do
      it "fails to retrieve config pattern" do
        api_basic_authorize action_identifier(:customization_scripts, :read, :resource_actions, :get)

        get api_customization_script_url(nil, 999_999)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
