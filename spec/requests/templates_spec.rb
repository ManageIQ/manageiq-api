RSpec.describe "Templates API" do
  describe "POST /api/templates/:c_id with DELETE action" do
    it "deletes a template with an appropriate role" do
      api_basic_authorize(action_identifier(:templates, :delete))
      template = FactoryBot.create(:template)

      expect do
        post(api_template_url(nil, template), :params => { :action => "delete" })
      end.to change(MiqTemplate, :count).by(-1)

      expected = {
        "href"    => api_template_url(nil, template),
        "message" => "templates id: #{template.id} deleting",
        "success" => true
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "won't delete a template without an appropriate role" do
      api_basic_authorize
      template = FactoryBot.create(:template)

      expect do
        post(api_template_url(nil, template), :params => { :action => "delete" })
      end.not_to change(MiqTemplate, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "editing a template" do
    let!(:template) { FactoryBot.create(:template, :name => 'foo', :description => 'bar') }
    before { api_basic_authorize(action_identifier(:templates, :edit)) }
    subject { send(req, api_template_url(nil, template), :params => params) }

    describe "PUT /api/templates/:c_id" do
      let(:req) { :put }
      let(:params) { {:name => 'baz'} }

      it 'edits the template name' do
        expect { subject }.to change { template.reload.name }.to('baz')
        expect(response).to have_http_status(:ok)
      end
    end

    describe "PATCH /api/templates/:c_id" do
      let(:req) { :patch }
      let(:params) { {:description => 'baz'} }

      it 'edits the template description' do
        expect { subject }.to change { template.reload.description }.to('baz')
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "check compliance action" do
    let(:template)             { FactoryBot.create(:template) }
    let(:template1)            { FactoryBot.create(:template) }
    let(:template2)            { FactoryBot.create(:template) }
    let(:invalid_template_url) { api_template_url(nil, ApplicationRecord.id_in_region(999_999, ApplicationRecord.my_region_number)) }
    let(:template_url)         { api_template_url(nil, template) }
    let(:template1_url)        { api_template_url(nil, template1) }
    let(:template2_url)        { api_template_url(nil, template2) }
    let!(:event_definition)    { FactoryBot.create(:miq_event_definition, :name => "vm_compliance_check") }
    let!(:policy_content) do
      content = FactoryBot.create(:miq_policy_content, :qualifier => "failure", :failure_sequence => 1)
      content.miq_action = FactoryBot.create(:miq_action, :name => "compliance_failed", :action_type => "default")
      content.miq_event_definition = event_definition
      content
    end

    let!(:compliance_policy) do
      policy = FactoryBot.create(:miq_policy, :mode => "compliance", :towhat => "Vm", :description => "check_compliance", :active => true)
      policy.conditions << FactoryBot.create(:condition)
      policy.miq_policy_contents << policy_content
      policy.sync_events([event_definition])
      policy
    end

    it "to an invalid template" do
      api_basic_authorize action_identifier(:templates, :check_compliance)

      post(invalid_template_url, :params => gen_request(:check_compliance))

      expect(response).to have_http_status(:not_found)
    end

    it "to an invalid template without appropriate role" do
      api_basic_authorize

      post(invalid_template_url, :params => gen_request(:check_compliance))

      expect(response).to have_http_status(:forbidden)
    end

    it "to a single template without compliance policies assigned" do
      api_basic_authorize action_identifier(:templates, :check_compliance)

      post(template_url, :params => gen_request(:check_compliance))

      expect_single_action_result(:success => false, :message => /template id:#{template.id} .* has no compliance policies assigned/i, :href => api_template_url(nil, template))
    end

    it "to a single template with a compliance policy" do
      api_basic_authorize action_identifier(:templates, :check_compliance)

      template.add_policy(compliance_policy)

      post(template_url, :params => gen_request(:check_compliance))

      expect_single_action_result(:success => true, :message => /template id:#{template.id} .* check compliance requested/i, :href => api_template_url(nil, template), :task => true)
    end

    it "to multiple templates without appropriate role" do
      api_basic_authorize

      post(api_templates_url, :params => gen_request(:check_compliance, [{"href" => template1_url}, {"href" => template2_url}]))

      expect(response).to have_http_status(:forbidden)
    end

    it "to multiple templates" do
      api_basic_authorize collection_action_identifier(:templates, :check_compliance)

      template1.add_policy(compliance_policy)

      post(api_templates_url, :params => gen_request(:check_compliance, [{"href" => template1_url}, {"href" => template2_url}]))

      expected = {
        "results" => a_collection_containing_exactly(
          a_hash_including(
            "message"   => a_string_matching(/Template id:#{template1.id} .* check compliance requested/i),
            "task_id"   => a_kind_of(String),
            "task_href" => a_string_matching(api_tasks_url),
            "success"   => true,
            "href"      => api_template_url(nil, template1)
          ),
          a_hash_including(
            "message" => a_string_matching(/Template id:#{template2.id} .* has no compliance policies assigned/i),
            "success" => false,
            "href"    => api_template_url(nil, template2)
          )
        )
      }

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "tags subcollection" do
    it "can list a template's tags" do
      template = FactoryBot.create(:template)
      FactoryBot.create(:classification_department_with_tags)
      Classification.classify(template, "department", "finance")
      api_basic_authorize

      get(api_template_tags_url(nil, template))

      expect(response.parsed_body).to include("subcount" => 1)
      expect(response).to have_http_status(:ok)
    end

    it "can assign a tag to a template" do
      template = FactoryBot.create(:template)
      FactoryBot.create(:classification_department_with_tags)
      api_basic_authorize(subcollection_action_identifier(:templates, :tags, :assign))

      post(api_template_tags_url(nil, template), :params => { :action => "assign", :category => "department", :name => "finance" })

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
      template = FactoryBot.create(:template)
      FactoryBot.create(:classification_department_with_tags)
      Classification.classify(template, "department", "finance")
      api_basic_authorize(subcollection_action_identifier(:templates, :tags, :unassign))

      post(
        api_template_tags_url(nil, template),
        :params => {
          :action   => "unassign",
          :category => "department",
          :name     => "finance"
        }
      )

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
