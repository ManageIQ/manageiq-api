RSpec.describe "Templates API" do
  describe "POST /api/templates/:c_id with DELETE action" do
    it "deletes a template with an appropriate role" do
      api_basic_authorize(action_identifier(:templates, :delete))
      template = FactoryBot.create(:template)

      expect do
        post(api_template_url(nil, template), :params => { :action => "delete" })
      end.to change(MiqTemplate, :count).by(-1)

      expect_single_action_result(
        :href    => api_template_url(nil, template),
        :message => /Deleting Template id: #{template.id}/,
        :success => true
      )
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
    let!(:template)     { FactoryBot.create(:template, :name => 'foo', :description => 'bar') }
    let(:ems)           { FactoryBot.create(:ems_vmware) }
    let(:host)          { FactoryBot.create(:host) }
    let(:template_openstack)       { FactoryBot.create(:template_openstack, :host => host, :ems_id => ems.id, :raw_power_state => "ACTIVE") }
    let(:template_openstack1)      { FactoryBot.create(:template_openstack, :host => host, :ems_id => ems.id, :raw_power_state => "ACTIVE") }
    let(:template_openstack2)      { FactoryBot.create(:template_openstack, :host => host, :ems_id => ems.id, :raw_power_state => "ACTIVE") }
    let(:new_vms) { FactoryBot.create_list(:template_openstack, 2) }
    before { api_basic_authorize(action_identifier(:templates, :edit)) }
    subject { send(req, api_template_url(nil, template), :params => params) }

    describe "POST /api/templates/:c_id" do
      it 'can edit a template with an appropriate role' do
        template.set_child(template_openstack)
        template.set_parent(template_openstack1)
        children = new_vms.collect do |vm|
          {'href' => api_template_url(nil, vm)}
        end
        post(
          api_template_url(nil, template),
          :params => {
            :action          => 'edit',
            :description     => 'bar',
            :name            => 'drew was here',
            :child_resources => children,
            :custom_1        => 'foobar',
            :parent_resource => {:href => api_template_url(nil, template_openstack2)}
          }
        )

        expected = {
          'description' => 'bar'
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
        expect(template.reload.children).to match_array(new_vms)
        expect(template.parent).to eq(template_openstack2)
        expect(template.name).to eq('drew was here')
        expect(template.custom_1).to eq('foobar')
      end
    end

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

  it_behaves_like "a check compliance action", "template", :template, "Vm"

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
