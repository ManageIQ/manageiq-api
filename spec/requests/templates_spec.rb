RSpec.describe "Templates API" do
  describe "POST /api/templates/:c_id with DELETE action" do
    it "deletes a template with an appropriate role" do
      api_basic_authorize(action_identifier(:templates, :delete))
      template = FactoryGirl.create(:template)

      expect do
        post(api_template_url(nil, template), :action => "delete")
      end.to change(MiqTemplate, :count).by(-1)

      expected = {
        "href"    => api_template_url(nil, template.compressed_id),
        "message" => "templates id: #{template.id} deleting",
        "success" => true
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "won't delete a template without an appropriate role" do
      api_basic_authorize
      template = FactoryGirl.create(:template)

      expect do
        post(api_template_url(nil, template), :action => "delete")
      end.not_to change(MiqTemplate, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "tags subcollection" do
    it "can list a template's tags" do
      template = FactoryGirl.create(:template)
      FactoryGirl.create(:classification_department_with_tags)
      Classification.classify(template, "department", "finance")
      api_basic_authorize

      get(api_template_tags_url(nil, template))

      expect(response.parsed_body).to include("subcount" => 1)
      expect(response).to have_http_status(:ok)
    end

    it "can assign a tag to a template" do
      template = FactoryGirl.create(:template)
      FactoryGirl.create(:classification_department_with_tags)
      api_basic_authorize(subcollection_action_identifier(:templates, :tags, :assign))

      post(api_template_tags_url(nil, template), :action => "assign", :category => "department", :name => "finance")

      expected = {
        "results" => [
          a_hash_including(
            "success"      => true,
            "message"      => a_string_matching(/assigning tag/i),
            "tag_category" => "department",
            "tag_name"     => "finance"
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can unassign a tag from a template" do
      template = FactoryGirl.create(:template)
      FactoryGirl.create(:classification_department_with_tags)
      Classification.classify(template, "department", "finance")
      api_basic_authorize(subcollection_action_identifier(:templates, :tags, :unassign))

      post(api_template_tags_url(nil, template),
               :action   => "unassign",
               :category => "department",
               :name     => "finance")

      expected = {
        "results" => [
          a_hash_including(
            "success"      => true,
            "message"      => a_string_matching(/unassigning tag/i),
            "tag_category" => "department",
            "tag_name"     => "finance"
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end
end
