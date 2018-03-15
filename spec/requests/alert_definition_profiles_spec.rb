describe "Alert Definition Profiles API" do
  describe "POST /api/alert_definition_profiles" do
    context "assign" do
      it "assigns alert profiles with an appropriate role" do
        api_basic_authorize(collection_action_identifier(:alert_definition_profiles, :edit))
        alert_definition_profile = FactoryGirl.create(:miq_alert_set)
        cluster = FactoryGirl.create(:ems_cluster)
        dept = FactoryGirl.create(:classification_department)
        tag = FactoryGirl.create(:classification_tag, :name => "foo", :parent => dept).tag

        request = {
          "action"    => "assign",
          "resources" => [
            { "id" => alert_definition_profile.id, "resources" => [
              {"href" => api_hosts_url, "tag" => { "href" => api_tag_url(nil, tag) }},
              {"href" => api_cluster_url(nil, cluster) }
            ]}
          ]
        }
        post(api_alert_definition_profiles_url, :params => request)

        expected = {
          "results" => [{"success" => true, "message" => /Assigned resources to Alert Definition Profile/}]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end

    context "unassign" do
      it "assigns alert profiles with an appropriate role" do
        api_basic_authorize(collection_action_identifier(:alert_definition_profiles, :edit))
        alert_definition_profile = FactoryGirl.create(:miq_alert_set)
        cluster = FactoryGirl.create(:ems_cluster)
        dept = FactoryGirl.create(:classification_department)
        classification = FactoryGirl.create(:classification_tag, :name => "foo", :parent => dept)
        alert_definition_profile.assign_to_tags([classification], "host")

        request = {
          "action"    => "unassign",
          "resources" => [
            { "id" => alert_definition_profile.id, "resources" => [
              {"href" => api_hosts_url, "tag" => { "href" => api_tag_url(nil, classification.tag) }},
              {"href" => api_cluster_url(nil, cluster) }
            ]}
          ]
        }
        post(api_alert_definition_profiles_url, :params => request)

        expected = {
          "results" => [{"success" => true, "message" => /Unassigned resources from Alert Definition Profile/}]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end

  describe "POST /api/alert_definition_profiles" do
    context "assign" do
      it "assigns alert profiles with an appropriate role" do
        api_basic_authorize(collection_action_identifier(:alert_definition_profiles, :edit))
        alert_definition_profile = FactoryGirl.create(:miq_alert_set)
        cluster = FactoryGirl.create(:ems_cluster)
        dept = FactoryGirl.create(:classification_department)
        tag = FactoryGirl.create(:classification_tag, :name => "foo", :parent => dept).tag

        request = {
          "action"    => "assign",
          "resources" => [
            {"href" => api_hosts_url, "tag" => { "href" => api_tag_url(nil, tag) }},
            {"href" => api_cluster_url(nil, cluster) }
          ]
        }
        post(api_alert_definition_profile_url(nil, alert_definition_profile), :params => request)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include("success" => true, "message" => /Assigned resources to Alert Definition Profile/)
      end
    end

    context "unassign" do
      it "unassigns objects and tags with an appropriate role" do
        api_basic_authorize(collection_action_identifier(:alert_definition_profiles, :edit))
        alert_definition_profile = FactoryGirl.create(:miq_alert_set)
        cluster = FactoryGirl.create(:ems_cluster)
        alert_definition_profile.assign_to_objects([cluster])
        dept = FactoryGirl.create(:classification_department)
        classification = FactoryGirl.create(:classification_tag, :name => "foo", :parent => dept)
        alert_definition_profile.assign_to_tags([classification], "host")

        request = {
          "action"    => "unassign",
          "resources" => [
            {"href" => api_hosts_url, "tag" => { "href" => api_tag_url(nil, classification.tag) }},
            {"href" => api_cluster_url(nil, cluster) }
          ]
        }
        post(api_alert_definition_profile_url(nil, alert_definition_profile), :params => request)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include("success" => true, "message" => /Unassigned resources from Alert Definition Profile/)
      end
    end
  end
end
