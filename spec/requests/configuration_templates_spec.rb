RSpec.describe "configuration templates API" do
  describe "display a configuration template's details" do
    context "with the user authorized" do
      it "responds with configuration template details" do
        config_template = FactoryGirl.create(:configuration_template,
                                             :ems_id  => 1,
                                             :ems_ref => "65",
                                             :name    => "server-template")

        api_basic_authorize action_identifier(:configuration_templates, :read, :resource_actions, :get)
        run_get(configuration_templates_url(config_template.id))

        expect_single_resource_query("ems_id"  => "1",
                                     "ems_ref" => "65",
                                     "name"    => "server-template")
      end
    end

    context "with the user unauthorized" do
      it "responds with a forbidden status" do
        config_template = FactoryGirl.create(:configuration_template)

        api_basic_authorize
        run_get(configuration_templates_url(config_template.id))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
