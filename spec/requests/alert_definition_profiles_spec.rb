describe "Alert Definition Profiles API" do
  let(:alert_definition_profile) { FactoryBot.create(:miq_alert_set) }
  let(:cluster) { FactoryBot.create(:ems_cluster) }
  let(:department_classification) { FactoryBot.create(:classification_department) }
  let(:classification_tag) { FactoryBot.create(:classification_tag, :parent => department_classification) }

  describe "POST /api/alert_definition_profiles" do
    context "assign" do
      it "requires a tag id, href, or classification name" do
        api_basic_authorize(collection_action_identifier(:alert_definition_profiles, :edit))

        request = {
          "action"    => "assign",
          "resources" => [
            { "id" => alert_definition_profile.id, "resources" => [
              {"href" => api_hosts_url, "tag" => {}}
            ]}
          ]
        }
        post(api_alert_definition_profiles_url, :params => request)

        expected = {
          "results" => [{"success" => false, "message" => /Must specify tag id, href, or name/}]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it "requires a resource href" do
        api_basic_authorize(collection_action_identifier(:alert_definition_profiles, :edit))

        request = {
          "action"    => "assign",
          "resources" => [
            { "id" => alert_definition_profile.id, "resources" => [{}]}
          ]
        }
        post(api_alert_definition_profiles_url, :params => request)

        expected = {
          "results" => [{"success" => false, "message" => /Must specify resource href/}]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it "assigns alert profiles with an appropriate role via tag href or classification name" do
        api_basic_authorize(collection_action_identifier(:alert_definition_profiles, :edit))
        cc_classification = FactoryBot.create(:classification_cost_center)
        FactoryBot.create(:classification_tag, :name => "bar", :parent => cc_classification)

        request = {
          "action"    => "assign",
          "resources" => [
            { "id" => alert_definition_profile.id, "resources" => [
              {"href" => api_hosts_url, "tag" => { "href" => api_tag_url(nil, classification_tag.tag) }},
              {"href" => api_hosts_url, "tag" => { "category" => cc_classification.name, "name" => "bar" }},
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
      it "requires a resource href" do
        api_basic_authorize(collection_action_identifier(:alert_definition_profiles, :edit))

        request = {
          "action"    => "unassign",
          "resources" => [
            { "id" => alert_definition_profile.id, "resources" => [{}]}
          ]
        }
        post(api_alert_definition_profiles_url, :params => request)

        expected = {
          "results" => [{"success" => false, "message" => /Must specify resource href/}]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it "unassigns alert profiles with an appropriate role via tag href or classification name" do
        api_basic_authorize(collection_action_identifier(:alert_definition_profiles, :edit))
        cc_classification = FactoryBot.create(:classification_cost_center)
        classification_tag2 = FactoryBot.create(:classification_tag, :name => "bar", :parent => cc_classification)
        alert_definition_profile.assign_to_tags([classification_tag], "host")
        alert_definition_profile.assign_to_tags([classification_tag2], "host")

        request = {
          "action"    => "unassign",
          "resources" => [
            { "id" => alert_definition_profile.id, "resources" => [
              {"href" => api_hosts_url, "tag" => { "id" => classification_tag.tag.id }},
              {"href" => api_hosts_url, "tag" => { "category" => cc_classification.name, "name" => "bar" }},
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

        request = {
          "action"    => "assign",
          "resources" => [
            {"href" => api_hosts_url, "tag" => { "href" => api_tag_url(nil, classification_tag.tag) }},
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
        alert_definition_profile.assign_to_objects([cluster])
        alert_definition_profile.assign_to_tags([classification_tag], "host")

        request = {
          "action"    => "unassign",
          "resources" => [
            {"href" => api_hosts_url, "tag" => { "href" => api_tag_url(nil, classification_tag.tag) }},
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
