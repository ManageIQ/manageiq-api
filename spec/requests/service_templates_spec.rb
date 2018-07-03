#
# Rest API Request Tests - Service Templates specs
#
# - Edit service template               /api/service_templates/:id    action "edit"
# - Edit multiple service templates     /api/service_templates        action "edit"
# - Delete service template             /api/service_templates/:id    DELETE
# - Delete multiple service templates   /api/service_templates        action "delete"
#
describe "Service Templates API" do
  let(:dialog1)    { FactoryGirl.create(:dialog, :label => "ServiceDialog1") }
  let(:dialog2)    { FactoryGirl.create(:dialog, :label => "ServiceDialog2") }

  let(:ra1)        { FactoryGirl.create(:resource_action, :action => "Provision", :dialog => dialog1) }
  let(:ra2)        { FactoryGirl.create(:resource_action, :action => "Retirement", :dialog => dialog2) }

  let(:picture)    { FactoryGirl.create(:picture, :extension => "jpg") }
  let(:template)   { FactoryGirl.create(:service_template, :name => "ServiceTemplate") }

  describe "Service Templates query" do
    before do
      template.resource_actions = [ra1, ra2]
      template.picture = picture
    end

    it "queries all resource actions of a Service Template" do
      api_basic_authorize

      get(api_service_template_resource_actions_url(nil, template), :params => { :expand => "resources" })

      resource_actions = template.resource_actions
      expect_query_result(:resource_actions, resource_actions.count, resource_actions.count)
      expect_result_resources_to_include_data("resources", "action" => resource_actions.pluck(:action))
    end

    it "queries a specific resource action of a Service Template" do
      api_basic_authorize

      get(
        api_service_template_resource_actions_url(nil, template),
        :params => {
          :expand => "resources",
          :filter => ["action='Provision'"]
        }
      )

      expect_query_result(:resource_actions, 1, 2)
      expect_result_resources_to_match_hash(["id" => ra1.id.to_s, "action" => ra1.action, "dialog_id" => dialog1.id.to_s])
    end

    it "allows queries of the related picture" do
      api_basic_authorize action_identifier(:service_templates, :read, :resource_actions, :get)

      get api_service_template_url(nil, template), :params => { :attributes => "picture" }

      expect_result_to_have_keys(%w(id href picture))
      expected = {"id" => template.id.to_s, "href" => api_service_template_url(nil, template)}
      expect_result_to_match_hash(response.parsed_body, expected)
    end

    it "allows queries of the related picture and image_href" do
      api_basic_authorize action_identifier(:service_templates, :read, :resource_actions, :get)

      get api_service_template_url(nil, template), :params => { :attributes => "picture,picture.image_href" }

      expect_result_to_have_keys(%w(id href picture))
      expect_result_to_match_hash(response.parsed_body["picture"],
                                  "id"          => picture.id.to_s,
                                  "resource_id" => template.id.to_s,
                                  "image_href"  => /^http:.*#{picture.image_href}$/)
    end

    it 'returns config_info for a specific service_template resource' do
      api_basic_authorize action_identifier(:service_templates, :read, :resource_actions, :get)

      get(api_service_template_url(nil, template))

      expected = {
        'config_info' => a_hash_including(
          "provision"  => a_hash_including(
            "dialog_id" => dialog1.id.to_s
          ),
          "retirement" => a_hash_including(
            "dialog_id" => dialog2.id.to_s
          )
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'does not return hrefs on resources that do not have a collection' do
      api_basic_authorize action_identifier(:service_templates, :read, :resource_actions, :get)
      vm = FactoryGirl.create(:vm)
      template.add_resource(vm)
      template.save

      get(api_service_template_url(nil, template), :params => {:attributes => 'service_resources'})

      expect(response).to have_http_status(:ok)
      response.parsed_body['service_resources'].each { |resource| expect(resource.keys).to_not include('href') }
    end

    context "with a schedule" do
      let(:st)            { FactoryGirl.create(:service_template, :name => "st") }
      let(:schedule_time) { Time.now.utc }
      let!(:schedule)     { st.order(@user, {}, {}, schedule_time.to_s) }

      it "gets the miq_schedule" do
        api_basic_authorize collection_action_identifier(:service_templates, :read, :get)

        get(api_service_template_url(nil, st), :params => {:attributes => 'miq_schedule'})

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["miq_schedule"]["run_at"]["start_time"]).to eq(schedule_time.iso8601)
      end

      it "gets the scheduled time" do
        api_basic_authorize collection_action_identifier(:service_templates, :read, :get)

        get(api_service_template_url(nil, st), :params => {:attributes => 'schedule_time'})

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["schedule_time"]).to eq(schedule_time.iso8601)
      end
    end
  end

  describe "Service Templates edit" do
    let(:ems) { FactoryGirl.create(:ems_amazon) }
    let(:new_vm) { FactoryGirl.create(:vm_amazon, :ext_management_system => ems) }
    let(:vm) { FactoryGirl.create(:vm_amazon, :ems_id => ems.id) }
    let(:flavor) { FactoryGirl.create(:flavor_amazon) }
    let(:dialog) { FactoryGirl.create(:miq_dialog_provision) }
    let(:request_dialog) { FactoryGirl.create(:miq_dialog_provision) }
    let(:service_dialog) { FactoryGirl.create(:dialog) }
    let(:updated_catalog_item_options) do
      {
        :name        => 'Updated Template Name',
        :display     => 'false',
        :description => 'a description',
        :config_info => {
          :miq_request_dialog_name => request_dialog.name,
          :placement_auto          => [true, 1],
          :number_of_vms           => [1, '1'],
          :src_vm_id               => [new_vm.id, new_vm.name],
          :vm_name                 => new_vm.name,
          :schedule_type           => ['immediately', 'Immediately on Approval'],
          :instance_type           => [flavor.id, flavor.name],
          :src_ems_id              => [ems.id, ems.name],
          :provision               => {
            :fqname    => ra1.fqname,
            :dialog_id => nil
          },
          :reconfigure             => {
            :fqname    => ra2.fqname,
            :dialog_id => service_dialog.id
          }
        }
      }
    end

    it "rejects requests without appropriate role" do
      api_basic_authorize

      st = FactoryGirl.create(:service_template, :name => "st")
      post(api_service_template_url(nil, st), :params => gen_request(:edit, updated_catalog_item_options))

      expect(response).to have_http_status(:forbidden)
    end

    it "supports edits of single resource" do
      api_basic_authorize collection_action_identifier(:service_templates, :edit)

      st = FactoryGirl.create(:service_template, :name => "st1")
      post(api_service_template_url(nil, st), :params => gen_request(:edit, updated_catalog_item_options))

      expect_single_resource_query("id" => st.id.to_s, "href" => api_service_template_url(nil, st), "name" => "Updated Template Name")
      expect(st.reload.name).to eq("Updated Template Name")
    end

    it "supports edits of multiple resources" do
      api_basic_authorize collection_action_identifier(:service_templates, :edit)

      st1 = FactoryGirl.create(:service_template, :name => "st1")
      st2 = FactoryGirl.create(:service_template, :name => "st2")

      post(api_service_templates_url, :params => gen_request(:edit, [updated_catalog_item_options.merge('id' => st1.id),
                                                                     updated_catalog_item_options.merge('id' => st2.id)]))

      expect(response).to have_http_status(:ok)
      expect_results_to_match_hash("results",
                                   [{"id" => st1.id.to_s, "name" => "Updated Template Name"},
                                    {"id" => st2.id.to_s, "name" => "Updated Template Name"}])
      expect(st1.reload.name).to eq("Updated Template Name")
      expect(st2.reload.name).to eq("Updated Template Name")
    end

    it 'can update without config info' do
      api_basic_authorize collection_action_identifier(:service_templates, :edit)
      st1 = FactoryGirl.create(:service_template, :name => 'st1')

      post(api_service_template_url(nil, st1), :params => gen_request(:edit, 'name' => 'updated template'))

      expected = {
        'id'   => st1.id.to_s,
        'name' => 'updated template'
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    context "with a schedule" do
      let(:st)        { FactoryGirl.create(:service_template, :name => "st") }
      let!(:schedule) { st.order(@user, {}, {}, Time.now.utc.to_s) }

      it "can update scheduled time" do
        api_basic_authorize collection_action_identifier(:service_templates, :edit)
        new_time = 1.day.from_now.utc
        post(api_service_template_url(nil, st), :params => { :action => "edit", :schedule_time => new_time.to_s })

        st.reload
        expect(st.schedule_time.to_s).to eq(new_time.to_s)
      end

      it "can delete a schedule" do
        api_basic_authorize collection_action_identifier(:service_templates, :edit)

        post(api_service_template_url(nil, st), :params => { :action => "edit", :schedule_time => nil })

        st.reload
        expect(st.schedule_time).to be_nil
        expect(st.miq_schedule).to be_nil
      end
    end
  end

  describe "Service Templates delete" do
    it "rejects requests without appropriate role" do
      api_basic_authorize

      post(api_service_templates_url, :params => gen_request(:delete, "href" => api_service_template_url(nil, 100)))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects resource deletion without appropriate role" do
      api_basic_authorize

      delete(api_service_template_url(nil, 100))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects resource deletes for invalid resources" do
      api_basic_authorize collection_action_identifier(:service_templates, :delete)

      delete(api_service_template_url(nil, 999_999))

      expect(response).to have_http_status(:not_found)
    end

    it "supports single resource deletes" do
      api_basic_authorize collection_action_identifier(:service_templates, :delete)

      st = FactoryGirl.create(:service_template, :name => "st", :description => "st description")

      delete(api_service_template_url(nil, st))

      expect(response).to have_http_status(:no_content)
      expect { st.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "can delete a service template via POST with an appropriate role" do
      api_basic_authorize(action_identifier(:service_templates, :delete))
      service_template = FactoryGirl.create(:service_template)

      expect do
        post(api_service_template_url(nil, service_template), :params => { :action => "delete" })
      end.to change(ServiceTemplate, :count).by(-1)

      expected = {
        "href"    => api_service_template_url(nil, service_template),
        "message" => "service_templates id: #{service_template.id} deleting",
        "success" => true
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "will not delete a service template via POST without an appropriate role" do
      api_basic_authorize
      service_template = FactoryGirl.create(:service_template)

      expect do
        post(api_service_template_url(nil, service_template), :params => { :action => "delete" })
      end.not_to change(ServiceTemplate, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "supports multiple resource deletes" do
      api_basic_authorize collection_action_identifier(:service_templates, :delete)

      st1 = FactoryGirl.create(:service_template, :name => "st1", :description => "st1 description")
      st2 = FactoryGirl.create(:service_template, :name => "st2", :description => "st2 description")

      post(api_service_templates_url, :params => gen_request(:delete,
                                                             [{"href" => api_service_template_url(nil, st1)},
                                                              {"href" => api_service_template_url(nil, st2)}]))
      expect_multiple_action_result(2)
      expect_result_resources_to_include_hrefs("results",
                                               [api_service_template_url(nil, st1), api_service_template_url(nil, st2)])

      expect { st1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { st2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "can delete a service template through its nested URI" do
      service_catalog = FactoryGirl.create(:service_template_catalog)
      service_template = FactoryGirl.create(:service_template, :service_template_catalog => service_catalog)
      api_basic_authorize action_identifier(:service_templates, :delete, :subresource_actions, :delete)

      expect do
        delete(api_service_catalog_service_template_url(nil, service_catalog, service_template))
      end.to change(ServiceTemplate, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "service requests subcollection" do
    it "can list a service template's service requests" do
      service_template = FactoryGirl.create(:service_template)
      service_request = FactoryGirl.create(:service_template_provision_request,
                                           :requester => @user,
                                           :source    => service_template)
      api_basic_authorize(action_identifier(:service_requests, :read, :subcollection_actions, :get))

      get(api_service_template_service_requests_url(nil, service_template))

      expected = {
        "count"     => 1,
        "subcount"  => 1,
        "name"      => "service_requests",
        "resources" => [
          {
            "href" => a_string_matching(
              api_service_template_service_request_url(nil, service_template, service_request)
            )
          }
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Service Templates create" do
    let(:ems) { FactoryGirl.create(:ems_amazon) }
    let(:vm) { FactoryGirl.create(:vm_amazon, :ems_id => ems.id) }
    let(:flavor) { FactoryGirl.create(:flavor_amazon) }
    let(:dialog) { FactoryGirl.create(:miq_dialog_provision) }
    let(:service_dialog) { FactoryGirl.create(:dialog) }
    let(:template_parameters) do
      {
        :name         => 'Atomic Service Template',
        :service_type => 'atomic',
        :prov_type    => 'amazon',
        :display      => 'false',
        :config_info  => {
          :miq_request_dialog_name => dialog.name,
          :placement_auto          => [true, 1],
          :number_of_vms           => [1, '1'],
          :src_vm_id               => [vm.id, vm.name],
          :vm_name                 => 'AtomicVMName',
          :schedule_type           => ["immediately", "Immediately on Approval"],
          :instance_type           => [flavor.id, flavor.name],
          :src_ems_id              => [ems.id, ems.name],
          :provision               => {
            :fqname    => ra1.fqname,
            :dialog_id => service_dialog.id
          },
          :retirement              => {
            :fqname    => ra2.fqname,
            :dialog_id => service_dialog.id
          }
        }
      }
    end

    it 'rejects requests without appropriate role' do
      api_basic_authorize

      post(api_service_templates_url, :params => { :name => 'foobar' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can create a single service template ' do
      api_basic_authorize collection_action_identifier(:service_templates, :create)

      expected = {
        'results' => a_collection_including(
          a_hash_including(
            'name'         => 'Atomic Service Template',
            'display'      => false,
            'service_type' => 'atomic',
            'prov_type'    => 'amazon'
          )
        )
      }

      expect do
        post(api_service_templates_url, :params => template_parameters)
      end.to change(ServiceTemplate, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can create multiple service templates' do
      api_basic_authorize collection_action_identifier(:service_templates, :create)

      template_hash = {
        'name'         => 'Atomic Service Template',
        'display'      => false,
        'service_type' => 'atomic',
        'prov_type'    => 'amazon'
      }
      expected = {
        'results' => a_collection_including(
          a_hash_including(
            template_hash
          ),
          a_hash_including(
            template_hash
          )
        )
      }
      expect do
        post(api_service_templates_url, :params => { :action => 'create', :resources => [template_parameters, template_parameters] })
      end.to change(ServiceTemplate, :count).by(2)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can create other resource types' do
      api_basic_authorize collection_action_identifier(:service_templates, :create)
      template = FactoryGirl.create(:orchestration_template)
      template_parameters = {
        :name         => 'Orchestration Template',
        :service_type => 'atomic',
        :prov_type    => 'generic_orchestration',
        :display      => 'false',
        :description  => 'a description',
        :config_info  => {
          :template_id => template.id,
          :manager_id  => ems.id,
          :provision   => {
            :fqname    => ra1.fqname,
            :dialog_id => service_dialog.id
          },
          :retirement  => {
            :fqname    => ra2.fqname,
            :dialog_id => service_dialog.id
          }
        }
      }

      expected = {
        'results' => [a_hash_including(
          'type' => 'ServiceTemplateOrchestration'
        )]
      }
      expect do
        post(api_service_templates_url, :params => template_parameters)
      end.to change(ServiceTemplateOrchestration, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'returns a bad request error for an invalid request' do
      api_basic_authorize collection_action_identifier(:service_templates, :create)
      template = FactoryGirl.create(:orchestration_template)
      template_parameters = {
        :name         => 'Orchestration Template',
        :service_type => 'atomic',
        :prov_type    => 'generic_orchestration',
        :display      => 'false',
        :description  => 'a description',
        :config_info  => {
          :template_id => template.id
        }
      }

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => a_string_including('Could not create Service Template')
        )
      }
      expect do
        post(api_service_templates_url, :params => template_parameters)
      end.to change(ServiceTemplateOrchestration, :count).by(0)
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Service Templates order" do
    let(:service_template) { FactoryGirl.create(:service_template, :with_provision_resource_action_and_dialog, :orderable) }

    it "is forbidden without appropriate role" do
      api_basic_authorize

      post(api_service_template_url(nil, service_template), :params => { :action => "order" })

      expect(response).to have_http_status(:forbidden)
    end

    context "with an orderable template" do
      it "can be ordered as a resource action" do
        api_basic_authorize action_identifier(:service_templates, :order, :resource_actions, :post)

        post(api_service_template_url(nil, service_template), :params => { :action => "order" })

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('href' => a_string_including(api_service_requests_url))
      end

      it "can be ordered as an action on the collection" do
        api_basic_authorize action_identifier(:service_templates, :order, :resource_actions, :post)

        post(api_service_templates_url, :params => { :action => "order", :resources => [{:href => api_service_template_url(nil, service_template)}] })

        expected = {
          "results" => [a_hash_including("href"    => a_string_including(api_service_requests_url),
                                         "options" => a_hash_including("request_options" => a_hash_including("submit_workflow"=>true)))]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it "shows the action" do
        api_basic_authorize(action_identifier(:service_templates, :order, :resource_actions, :post),
                            action_identifier(:service_templates, :read, :resource_actions, :get))

        get(api_service_template_url(nil, service_template))

        actions = response.parsed_body["actions"].collect { |action| action["name"] }
        expect(actions).to include("order")
      end

      it "can order multiple service templates" do
        service_template2 = FactoryGirl.create(:service_template, :with_provision_resource_action_and_dialog, :orderable)
        api_basic_authorize action_identifier(:service_templates, :order, :resource_actions, :post)

        post(api_service_templates_url, :params => { :action => "order", :resources =>
          [{:href => api_service_template_url(nil, service_template)},
           {:href => api_service_template_url(nil, service_template2)}]})

        expected = {
          "results" => [a_hash_including("href" => a_string_including(api_service_requests_url)),
                        a_hash_including("href" => a_string_including(api_service_requests_url))]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      context "with a schedule_time" do
        it "can be ordered as a resource action" do
          api_basic_authorize action_identifier(:service_templates, :order, :resource_actions, :post)

          post(api_service_template_url(nil, service_template), :params => { :action => "order", :schedule_time => Time.now.utc.to_s })

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include("name"=>"Order ServiceTemplate #{ServiceTemplate.first.id}")
        end

        it "can be ordered as an action on the collection" do
          api_basic_authorize action_identifier(:service_templates, :order, :resource_actions, :post)

          post(api_service_templates_url, :params => { :action => "order", :resources => [{:href => api_service_template_url(nil, service_template), :schedule_time => Time.now.utc.to_s}] })

          expected = {
            "results" => [a_hash_including("name"=>"Order ServiceTemplate #{ServiceTemplate.first.id}")]
          }
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(expected)
        end
      end
    end

    context "with an unorderable template" do
      let(:template_no_display) { FactoryGirl.create(:service_template, :display => false) }

      it "cannot be ordered" do
        api_basic_authorize action_identifier(:service_templates, :order, :resource_actions, :post)

        post(api_service_template_url(nil, template_no_display), :params => { :action => "order" })

        expected = {
          "error" => a_hash_including(
            "kind"    => "bad_request",
            "message" => /cannot be ordered/
          )
        }
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to include(expected)
      end

      it "does not show the order action" do
        api_basic_authorize(action_identifier(:service_templates, :order, :resource_actions, :post),
                            action_identifier(:service_templates, :read, :resource_actions, :get),
                            action_identifier(:service_templates, :edit, :resource_actions, :post))

        get(api_service_template_url(nil, template_no_display))

        actions = response.parsed_body["actions"].collect { |action| action["name"] }
        expect(actions).to_not include("order")
      end
    end
  end

  describe "Service Templates archive" do
    let(:service_template) { FactoryGirl.create(:service_template, :with_provision_resource_action_and_dialog) }

    it "is forbidden without appropriate role" do
      api_basic_authorize

      post(api_service_template_url(nil, service_template), :params => { :action => "archive" })

      expect(response).to have_http_status(:forbidden)
    end

    it "can be archived as a resource action" do
      api_basic_authorize action_identifier(:service_templates, :archive, :resource_actions, :post)

      post(api_service_template_url(nil, service_template), :params => { :action => "archive" })

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("message" => "Archived Service Template")
    end

    it "can be archived as an action on the collection" do
      api_basic_authorize action_identifier(:service_templates, :archive, :resource_actions, :post)

      post(api_service_templates_url, :params => { :action => "archive", :resources => [{:href => api_service_template_url(nil, service_template)}] })

      expected = {
        "results" => [a_hash_including("message" => "Archived Service Template")]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "shows the action" do
      api_basic_authorize(action_identifier(:service_templates, :archive, :resource_actions, :post),
                          action_identifier(:service_templates, :read, :resource_actions, :get))

      get(api_service_template_url(nil, service_template))

      actions = response.parsed_body["actions"].collect { |action| action["name"] }
      expect(actions).to include("archive")
    end

    it "can archive multiple service templates" do
      service_template2 = FactoryGirl.create(:service_template, :with_provision_resource_action_and_dialog)
      api_basic_authorize action_identifier(:service_templates, :archive, :resource_actions, :post)

      post(api_service_templates_url, :params => { :action => "archive", :resources =>
        [{:href => api_service_template_url(nil, service_template)},
         {:href => api_service_template_url(nil, service_template2)}]})

      expected = {
        "results" => [a_hash_including("message" => "Archived Service Template"),
                      a_hash_including("message" => "Archived Service Template")]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Service Templates unarchive" do
    let(:service_template) { FactoryGirl.create(:service_template, :with_provision_resource_action_and_dialog) }

    it "is forbidden without appropriate role" do
      api_basic_authorize

      post(api_service_template_url(nil, service_template), :params => { :action => "unarchive" })

      expect(response).to have_http_status(:forbidden)
    end

    it "can be unarchived as a resource action" do
      api_basic_authorize action_identifier(:service_templates, :unarchive, :resource_actions, :post)

      post(api_service_template_url(nil, service_template), :params => { :action => "unarchive" })

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("message" => "Unarchived Service Template")
    end

    it "can be unarchived as an action on the collection" do
      api_basic_authorize action_identifier(:service_templates, :unarchive, :resource_actions, :post)

      post(api_service_templates_url, :params => { :action => "unarchive", :resources => [{:href => api_service_template_url(nil, service_template)}] })

      expected = {
        "results" => [a_hash_including("message" => "Unarchived Service Template")]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "shows the action" do
      api_basic_authorize(action_identifier(:service_templates, :unarchive, :resource_actions, :post),
                          action_identifier(:service_templates, :read, :resource_actions, :get))

      get(api_service_template_url(nil, service_template))

      actions = response.parsed_body["actions"].collect { |action| action["name"] }
      expect(actions).to include("unarchive")
    end

    it "can unarchive multiple service templates" do
      service_template2 = FactoryGirl.create(:service_template, :with_provision_resource_action_and_dialog)
      api_basic_authorize action_identifier(:service_templates, :unarchive, :resource_actions, :post)

      post(api_service_templates_url, :params => { :action => "unarchive", :resources =>
        [{:href => api_service_template_url(nil, service_template)},
         {:href => api_service_template_url(nil, service_template2)}]})

      expected = {
        "results" => [a_hash_including("message" => "Unarchived Service Template"),
                      a_hash_including("message" => "Unarchived Service Template")]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
