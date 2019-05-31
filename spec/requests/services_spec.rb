#
# Rest API Request Tests - Services specs
#
# - Create service              /api/services/        action "create"
#
# - Edit service                /api/services/:id     action "edit"
# - Edit service via PUT        /api/services/:id     PUT
# - Edit service via PATCH      /api/services/:id     PATCH
# - Edit multiple services      /api/services         action "edit"
#
# - Delete service              /api/services/:id     DELETE
# - Delete multiple services    /api/services         action "delete"
#
# - Retire service now          /api/services/:id     action "retire"
# - Retire service future       /api/services/:id     action "retire"
# - Retire multiple services    /api/services         action "retire"
#
# - Reconfigure service         /api/services/:id     action "reconfigure"
#
# - Query vms subcollection     /api/services/:id/vms
#                               /api/services/:id?expand=vms
#   with subcollection
#   virtual attribute:          /api/services/:id?expand=vms&attributes=vms.cpu_total_cores
#
describe "Services API" do
  let(:svc)  { FactoryGirl.create(:service, :name => "svc",  :description => "svc description")  }
  let(:svc1) { FactoryGirl.create(:service, :name => "svc1", :description => "svc1 description") }
  let(:svc2) { FactoryGirl.create(:service, :name => "svc2", :description => "svc2 description") }
  let(:svc_orchestration) { FactoryGirl.create(:service_orchestration) }
  let(:orchestration_template) { FactoryGirl.create(:orchestration_template) }
  let(:ems) { FactoryGirl.create(:ext_management_system) }

  describe "Services create" do
    it "rejects requests without appropriate role" do
      api_basic_authorize

      post(api_services_url, :params => gen_request(:create, "name" => "svc_new_1"))

      expect(response).to have_http_status(:forbidden)
    end

    it "supports creates of single resource" do
      api_basic_authorize collection_action_identifier(:services, :create)

      expect do
        post(api_services_url, :params => gen_request(:create, "name" => "svc_new_1"))
      end.to change(Service, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect_results_to_match_hash("results", [{"name" => "svc_new_1"}])
    end

    it "supports creates of multiple resources" do
      api_basic_authorize collection_action_identifier(:services, :create)

      expect do
        post(api_services_url, :params => gen_request(:create,
                                                      [{"name" => "svc_new_1"},
                                                       {"name" => "svc_new_2"}]))
      end.to change(Service, :count).by(2)

      expect(response).to have_http_status(:ok)
      expect_results_to_match_hash("results",
                                   [{"name" => "svc_new_1"},
                                    {"name" => "svc_new_2"}])
    end

    it 'supports creation of a single resource with href references' do
      api_basic_authorize collection_action_identifier(:services, :create)

      request = {
        'action'   => 'create',
        'resource' => {
          'type'                   => 'ServiceOrchestration',
          'name'                   => 'svc_new',
          'parent_service'         => { 'href' => api_service_url(nil, svc1)},
          'orchestration_template' => { 'href' => api_orchestration_template_url(nil, orchestration_template) },
          'orchestration_manager'  => { 'href' => api_provider_url(nil, ems) }
        }
      }
      expect do
        post(api_services_url, :params => request)
      end.to change(Service, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect_results_to_match_hash("results", [{"name" => "svc_new"}])
    end

    it 'supports creation of a single resource with id references' do
      api_basic_authorize collection_action_identifier(:services, :create)

      request = {
        'action'   => 'create',
        'resource' => {
          'type'                   => 'ServiceOrchestration',
          'name'                   => 'svc_new',
          'parent_service'         => { 'id' => svc1.id},
          'orchestration_template' => { 'id' => orchestration_template.id },
          'orchestration_manager'  => { 'id' => ems.id }
        }
      }
      expect do
        post(api_services_url, :params => request)
      end.to change(Service, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect_results_to_match_hash("results", [{"name" => "svc_new"}])
    end
  end

  describe "Services edit" do
    it "rejects requests without appropriate role" do
      api_basic_authorize

      post(api_service_url(nil, svc), :params => gen_request(:edit, "name" => "sample service"))

      expect(response).to have_http_status(:forbidden)
    end

    it "supports edits of single resource" do
      api_basic_authorize collection_action_identifier(:services, :edit)

      post(api_service_url(nil, svc), :params => gen_request(:edit, "name" => "updated svc1"))

      expect_single_resource_query("id" => svc.id.to_s, "href" => api_service_url(nil, svc), "name" => "updated svc1")
      expect(svc.reload.name).to eq("updated svc1")
    end

    it 'accepts reference signature hrefs' do
      api_basic_authorize collection_action_identifier(:services, :edit)

      resource = {
        'action'   => 'edit',
        'resource' => {
          'parent_service'         => { 'href' => api_service_url(nil, svc1) },
          'orchestration_template' => { 'href' => api_orchestration_template_url(nil, orchestration_template) },
          'orchestration_manager'  => { 'href' => api_provider_url(nil, ems) }
        }
      }
      post(api_service_url(nil, svc_orchestration), :params => resource)

      expected = {
        'id'       => svc_orchestration.id.to_s,
        'ancestry' => svc1.id.to_s
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
      expect(svc_orchestration.reload.parent).to eq(svc1)
      expect(svc_orchestration.orchestration_template).to eq(orchestration_template)
      expect(svc_orchestration.orchestration_manager).to eq(ems)
    end

    it 'accepts reference signature ids' do
      api_basic_authorize collection_action_identifier(:services, :edit)

      resource = {
        'action'   => 'edit',
        'resource' => {
          'parent_service'         => { 'id' => svc1.id },
          'orchestration_template' => { 'id' => orchestration_template.id },
          'orchestration_manager'  => { 'id' => ems.id }
        }
      }
      post(api_service_url(nil, svc_orchestration), :params => resource)

      expected = {
        'id'       => svc_orchestration.id.to_s,
        'ancestry' => svc1.id.to_s
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
      expect(svc_orchestration.reload.parent).to eq(svc1)
      expect(svc_orchestration.orchestration_template).to eq(orchestration_template)
      expect(svc_orchestration.orchestration_manager).to eq(ems)
    end

    it "supports edits of single resource via PUT" do
      api_basic_authorize collection_action_identifier(:services, :edit)

      put(api_service_url(nil, svc), :params => { "name" => "updated svc1" })

      expect_single_resource_query("id" => svc.id.to_s, "href" => api_service_url(nil, svc), "name" => "updated svc1")
      expect(svc.reload.name).to eq("updated svc1")
    end

    it "supports edits of single resource via PATCH" do
      api_basic_authorize collection_action_identifier(:services, :edit)

      patch(api_service_url(nil, svc), :params => [{"action" => "edit",   "path" => "name", "value" => "updated svc1"},
                                                   {"action" => "remove", "path" => "description"},
                                                   {"action" => "add",    "path" => "display", "value" => true}])

      expect_single_resource_query("id" => svc.id.to_s, "name" => "updated svc1", "display" => true)
      expect(svc.reload.name).to eq("updated svc1")
      expect(svc.description).to be_nil
      expect(svc.display).to be_truthy
    end

    it "supports edits of single resource via a standard PATCH" do
      api_basic_authorize collection_action_identifier(:services, :edit)

      updated_service_attributes = { "name" => "updated svc1", "description" => nil, "display" => true }

      patch(api_service_url(nil, svc), :params => updated_service_attributes)

      expect_single_resource_query("id" => svc.id.to_s)
      expect(svc.reload.attributes).to include(updated_service_attributes)
    end

    it "supports edits of multiple resources" do
      api_basic_authorize collection_action_identifier(:services, :edit)

      post(api_services_url, :params => gen_request(:edit,
                                                    [{"href" => api_service_url(nil, svc1), "name" => "updated svc1"},
                                                     {"href" => api_service_url(nil, svc2), "name" => "updated svc2"}]))

      expect(response).to have_http_status(:ok)
      expect_results_to_match_hash("results",
                                   [{"id" => svc1.id.to_s, "name" => "updated svc1"},
                                    {"id" => svc2.id.to_s, "name" => "updated svc2"}])
      expect(svc1.reload.name).to eq("updated svc1")
      expect(svc2.reload.name).to eq("updated svc2")
    end
  end

  describe "Services delete" do
    it "rejects POST delete requests without appropriate role" do
      api_basic_authorize

      post(api_services_url, :params => gen_request(:delete, "href" => api_service_url(nil, 100)))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects DELETE requests without appropriate role" do
      api_basic_authorize

      delete(api_service_url(nil, 100))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects requests for invalid resources" do
      api_basic_authorize collection_action_identifier(:services, :delete)

      delete(api_service_url(nil, 999_999))

      expect(response).to have_http_status(:not_found)
    end

    it "supports single resource deletes" do
      api_basic_authorize collection_action_identifier(:services, :delete)

      delete(api_service_url(nil, svc))

      expect(response).to have_http_status(:no_content)
      expect { svc.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "can be deleted via POST with an appropriate role" do
      service = FactoryGirl.create(:service)
      api_basic_authorize(action_identifier(:services, :delete))

      expect do
        post(api_service_url(nil, service), :params => { :action => "delete" })
      end.to change(Service, :count).by(-1)

      expected = {
        "success" => true,
        "message" => "services id: #{service.id} deleting",
        "href"    => api_service_url(nil, service)
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "won't delete a service via POST without an appropriate role" do
      service = FactoryGirl.create(:service)
      api_basic_authorize

      expect do
        post(api_service_url(nil, service), :params => { :action => "delete" })
      end.not_to change(Service, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "supports multiple resource deletes" do
      api_basic_authorize collection_action_identifier(:services, :delete)

      post(api_services_url, :params => gen_request(:delete,
                                                    [{"href" => api_service_url(nil, svc1)},
                                                     {"href" => api_service_url(nil, svc2)}]))
      expect_multiple_action_result(2)
      expect_result_resources_to_include_hrefs("results",
                                               [api_service_url(nil, svc1), api_service_url(nil, svc2)])
      expect { svc1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { svc2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns correct action response messages" do
      api_basic_authorize collection_action_identifier(:services, :delete)

      post(api_services_url, :params => gen_request(:delete,
                                                    [{"href" => api_service_url(nil, 0)},
                                                     {"href" => api_service_url(nil, svc)}]))
      expected = {
        "results" => [
          a_hash_including("success" => false, "message" => "Couldn't find Service with 'id'=0"),
          a_hash_including("success" => true, "message" => "services id: #{svc.id} deleting")
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Services retirement" do
    def format_retirement_date(time)
      time.in_time_zone('UTC').strftime("%Y-%m-%dT%H:%M:%SZ")
    end

    context "retire_now" do
      it "rejects requests without appropriate role" do
        api_basic_authorize

        post(api_service_url(nil, 100), :params => gen_request(:retire))

        expect(response).to have_http_status(:forbidden)
      end

      it "rejects multiple requests without appropriate role" do
        api_basic_authorize

        post(api_services_url, :params => gen_request(:retire, [{"href" => api_service_url(nil, 1)}, {"href" => api_service_url(nil, 2)}]))

        expect(response).to have_http_status(:forbidden)
      end

      it "supports single service retirement now" do
        api_basic_authorize collection_action_identifier(:services, :retire)

        expect(MiqEvent).to receive(:raise_evm_event).once

        post(api_service_url(nil, svc), :params => gen_request(:retire))

        expect_single_resource_query("id" => svc.id.to_s, "href" => api_service_url(nil, svc))
      end

      it "supports single service retirement in future" do
        api_basic_authorize collection_action_identifier(:services, :retire)

        ret_date = format_retirement_date(Time.zone.now + 5.days)

        post(api_service_url(nil, svc), :params => gen_request(:retire, "date" => ret_date, "warn" => 2))

        expect_single_resource_query("id" => svc.id.to_s, "retires_on" => ret_date, "retirement_warn" => 2)
        expect(format_retirement_date(svc.reload.retires_on)).to eq(ret_date)
        expect(svc.retirement_warn).to eq(2)
      end

      it "supports multiple service retirement now" do
        api_basic_authorize collection_action_identifier(:services, :retire)

        expect(MiqEvent).to receive(:raise_evm_event).twice

        post(api_services_url, :params => gen_request(:retire,
                                                      [{"href" => api_service_url(nil, svc1)},
                                                       {"href" => api_service_url(nil, svc2)}]))

        expect_results_to_match_hash("results", [{"id" => svc1.id.to_s}, {"id" => svc2.id.to_s}])
      end

      it "supports multiple service retirement in future" do
        api_basic_authorize collection_action_identifier(:services, :retire)

        ret_date = format_retirement_date(Time.zone.now + 2.days)

        post(api_services_url, :params => gen_request(:retire,
                                                      [{"href" => api_service_url(nil, svc1), "date" => ret_date, "warn" => 3},
                                                       {"href" => api_service_url(nil, svc2), "date" => ret_date, "warn" => 5}]))

        expect_results_to_match_hash("results",
                                     [{"id" => svc1.id.to_s, "retires_on" => ret_date, "retirement_warn" => 3},
                                      {"id" => svc2.id.to_s, "retires_on" => ret_date, "retirement_warn" => 5}])
        expect(format_retirement_date(svc1.reload.retires_on)).to eq(ret_date)
        expect(svc1.retirement_warn).to eq(3)
        expect(format_retirement_date(svc2.reload.retires_on)).to eq(ret_date)
        expect(svc2.retirement_warn).to eq(5)
      end
    end

    context "request_retire" do
      context "bad permissions" do
        it "rejects requests without appropriate role" do
          api_basic_authorize

          post(api_service_url(nil, 100), :params => gen_request(:request_retire))

          expect(response).to have_http_status(:forbidden)
        end

        it "rejects multiple requests without appropriate role" do
          api_basic_authorize

          post(api_services_url, :params => gen_request(:request_retire, [{"href" => api_service_url(nil, 1)}, {"href" => api_service_url(nil, 2)}]))

          expect(response).to have_http_status(:forbidden)
        end
      end

      context "good permissions" do
        it "supports single service retirement now" do
          api_basic_authorize(action_identifier(:services, :request_retire))

          post(api_service_url(nil, svc), :params => gen_request(:request_retire))

          expected = {
            "href"    => a_string_matching(api_requests_url),
            "message" => a_string_matching(/Service Retire - Request Created/),
            "options" => a_hash_including("src_ids" => a_collection_including(svc.id))
          }
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(expected)
        end

        it "supports multiple service retirement now" do
          api_basic_authorize collection_action_identifier(:services, :request_retire)

          post(api_services_url, :params => gen_request(:retire,
                                                        [{"href" => api_service_url(nil, svc1)},
                                                         {"href" => api_service_url(nil, svc2)}]))

          expect_results_to_match_hash("results", [{"id" => svc1.id.to_s}, {"id" => svc2.id.to_s}])
        end
      end
    end
  end

  describe "Service reconfiguration" do
    let(:dialog1) { FactoryGirl.create(:dialog_with_tab_and_group_and_field) }
    let(:st1)     { FactoryGirl.create(:service_template, :name => "template1") }
    let(:ra1) do
      FactoryGirl.create(:resource_action, :action => "Reconfigure", :dialog => dialog1,
                         :ae_namespace => "namespace", :ae_class => "class", :ae_instance => "instance")
    end

    it "rejects requests without appropriate role" do
      api_basic_authorize

      post(api_service_url(nil, 100), :params => gen_request(:reconfigure))

      expect(response).to have_http_status(:forbidden)
    end

    it "does not return reconfigure action for non-reconfigurable services" do
      api_basic_authorize(action_identifier(:services, :read, :resource_actions, :get),
                          action_identifier(:services, :retire),
                          action_identifier(:services, :reconfigure))

      get api_service_url(nil, svc1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to declare_actions("retire", "request_retire")
    end

    it "returns reconfigure action for reconfigurable services" do
      api_basic_authorize(action_identifier(:services, :read, :resource_actions, :get),
                          action_identifier(:services, :retire),
                          action_identifier(:services, :reconfigure))

      st1.resource_actions = [ra1]
      svc1.service_template_id = st1.id
      svc1.save

      get api_service_url(nil, svc1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to declare_actions("retire", "request_retire", "reconfigure")
    end

    it "accepts action when service is reconfigurable" do
      api_basic_authorize action_identifier(:services, :reconfigure)

      st1.resource_actions = [ra1]
      svc1.service_template_id = st1.id
      svc1.save

      post(api_service_url(nil, svc1), :params => gen_request(:reconfigure, "text1" => "updated_text"))

      expect_single_action_result(:success => true, :message => /reconfiguring/i, :href => api_service_url(nil, svc1))
    end
  end

  describe "Services" do
    let(:hw1) { FactoryGirl.build(:hardware, :cpu_total_cores => 2) }
    let(:vm1) { FactoryGirl.create(:vm_vmware, :hardware => hw1, :evm_owner_id => @user.id) }

    let(:hw2) { FactoryGirl.build(:hardware, :cpu_total_cores => 4) }
    let(:vm2) { FactoryGirl.create(:vm_vmware, :hardware => hw2, :evm_owner_id => @user.id) }

    let(:super_admin) { FactoryGirl.create(:user, :role => 'super_administrator', :userid => 'admin', :password => 'adminpassword') }
    let(:hw3) { FactoryGirl.build(:hardware, :cpu_total_cores => 6) }
    let(:vm3) { FactoryGirl.create(:vm_vmware, :hardware => hw3, :evm_owner_id => super_admin.id) }

    before do
      @user.current_group.miq_user_role.update_attributes(:settings => {:restrictions => {:vms => :user_or_group}})
      api_basic_authorize(action_identifier(:services, :read, :resource_actions, :get))

      svc1 << vm1
      svc1 << vm2
      svc1 << vm3
      svc1.evm_owner_id = @user.id
      svc1.save
    end

    def expect_svc_with_vms
      expect_single_resource_query("href" => api_service_url(nil, svc1))
      expect_result_resources_to_include_hrefs("vms",
                                               [api_service_vm_url(nil, svc1, vm1), api_service_vm_url(nil, svc1, vm2)])
    end

    it "can query vms as subcollection" do
      get(api_service_vms_url(nil, svc1))

      expect_query_result(:vms, 2, 3)
      expect_result_resources_to_include_hrefs("resources",
                                               [api_service_vm_url(nil, svc1, vm1),
                                                api_service_vm_url(nil, svc1, vm2)])
    end

    it "supports expansion of virtual attributes" do
      get api_services_url, :params => { :expand => "resources", :attributes => "power_states" }

      expected = {
        "resources" => [
          a_hash_including("power_states" => svc1.power_states)
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "can query vms as subcollection via expand" do
      get api_service_url(nil, svc1), :params => { :expand => "vms" }

      expect_svc_with_vms
    end

    it "can query vms as subcollection via expand with additional virtual attributes" do
      get api_service_url(nil, svc1), :params => { :expand => "vms", :attributes => "vms.cpu_total_cores" }

      expect_svc_with_vms
      expect_results_to_match_hash("vms", [{"id" => vm1.id.to_s, "cpu_total_cores" => 2},
                                           {"id" => vm2.id.to_s, "cpu_total_cores" => 4}])
    end

    it "cannot query vms via both virtual attribute and subcollection" do
      get api_service_url(nil, svc1), :params => { :expand => "vms", :attributes => "vms" }

      expect_bad_request("Cannot expand subcollection vms by name and virtual attribute")
    end

    it "can query all vms as subcollection via expand as admin user" do
      request_headers['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(super_admin.userid, super_admin.password)
      get api_service_url(nil, svc1), :params => { :expand => "vms" }
      expect_single_resource_query("href" => api_service_url(nil, svc1))
      expect_result_resources_to_include_hrefs("vms",
                                               [api_service_vm_url(nil, svc1, vm1), api_service_vm_url(nil, svc1, vm2), api_service_vm_url(nil, svc1, vm3)])
    end
  end

  describe "Power Operations" do
    describe "start" do
      it "will start a service for a user with appropriate role" do
        service = FactoryGirl.create(:service)
        api_basic_authorize(action_identifier(:services, :start))

        post(api_service_url(nil, service), :params => { :action => "start" })

        expected = {
          "href"    => api_service_url(nil, service),
          "success" => true,
          "message" => a_string_matching("starting")
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "can start multiple services for a user with appropriate role" do
        service_1, service_2 = FactoryGirl.create_list(:service, 2)
        api_basic_authorize(collection_action_identifier(:services, :start))

        post(api_services_url, :params => { :action => "start", :resources => [{:id => service_1.id}, {:id => service_2.id}] })

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including("success"   => true,
                             "message"   => a_string_matching("starting"),
                             "task_id"   => anything,
                             "task_href" => anything,
                             "href"      => api_service_url(nil, service_1)),
            a_hash_including("success"   => true,
                             "message"   => a_string_matching("starting"),
                             "task_id"   => anything,
                             "task_href" => anything,
                             "href"      => api_service_url(nil, service_2)),
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not start a service for a user without an appropriate role" do
        service = FactoryGirl.create(:service)
        api_basic_authorize

        post(api_service_url(nil, service), :params => { :action => "start" })

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "stop" do
      it "will stop a service for a user with appropriate role" do
        service = FactoryGirl.create(:service)
        api_basic_authorize(action_identifier(:services, :stop))

        post(api_service_url(nil, service), :params => { :action => "stop" })

        expected = {
          "href"    => api_service_url(nil, service),
          "success" => true,
          "message" => a_string_matching("stopping")
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "can stop multiple services for a user with appropriate role" do
        service_1, service_2 = FactoryGirl.create_list(:service, 2)
        api_basic_authorize(collection_action_identifier(:services, :stop))

        post(api_services_url, :params => { :action => "stop", :resources => [{:id => service_1.id}, {:id => service_2.id}] })

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including("success"   => true,
                             "message"   => a_string_matching("stopping"),
                             "task_id"   => anything,
                             "task_href" => anything,
                             "href"      => api_service_url(nil, service_1)),
            a_hash_including("success"   => true,
                             "message"   => a_string_matching("stopping"),
                             "task_id"   => anything,
                             "task_href" => anything,
                             "href"      => api_service_url(nil, service_2)),
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not stop a service for a user without an appropriate role" do
        service = FactoryGirl.create(:service)
        api_basic_authorize

        post(api_service_url(nil, service), :params => { :action => "stop" })

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "suspend" do
      it "will suspend a service for a user with appropriate role" do
        service = FactoryGirl.create(:service)
        api_basic_authorize(action_identifier(:services, :suspend))

        post(api_service_url(nil, service), :params => { :action => "suspend" })

        expected = {
          "href"    => api_service_url(nil, service),
          "success" => true,
          "message" => a_string_matching("suspending")
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "can suspend multiple services for a user with appropriate role" do
        service_1, service_2 = FactoryGirl.create_list(:service, 2)
        api_basic_authorize(collection_action_identifier(:services, :suspend))

        post(api_services_url, :params => { :action => "suspend", :resources => [{:id => service_1.id}, {:id => service_2.id}] })

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including("success"   => true,
                             "message"   => a_string_matching("suspending"),
                             "task_id"   => anything,
                             "task_href" => anything,
                             "href"      => api_service_url(nil, service_1)),
            a_hash_including("success"   => true,
                             "message"   => a_string_matching("suspending"),
                             "task_id"   => anything,
                             "task_href" => anything,
                             "href"      => api_service_url(nil, service_2)),
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not suspend a service for a user without an appropriate role" do
        service = FactoryGirl.create(:service)
        api_basic_authorize

        post(api_service_url(nil, service), :params => { :action => "suspend" })

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'Orchestration Stack subcollection' do
    let(:os) { FactoryGirl.create(:orchestration_stack) }

    before do
      svc.add_resource!(os, :name => ResourceAction::PROVISION)
    end

    it 'can query orchestration stacks as a subcollection' do
      api_basic_authorize subcollection_action_identifier(:services, :orchestration_stacks, :read, :get)

      get(api_service_orchestration_stacks_url(nil, svc), :params => { :expand => 'resources' })

      expected = {
        'resources' => [
          a_hash_including('id' => os.id.to_s)
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can query a specific orchestration stack' do
      api_basic_authorize(subresource_action_identifier(:services, :orchestration_stacks, :read, :get))

      get(api_service_orchestration_stack_url(nil, svc, os))

      expected = {'id' => os.id.to_s}
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can query a specific orchestration stack asking for stdout' do
      api_basic_authorize(subresource_action_identifier(:services, :orchestration_stacks, :read, :get))

      allow_any_instance_of(OrchestrationStack).to receive(:stdout).with(nil).and_return("default text stdout")
      get(api_service_orchestration_stack_url(nil, svc, os), :params => { :attributes => "stdout" })

      expected = {
        'id'     => os.id.to_s,
        'stdout' => "default text stdout"
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can query a specific orchestration stack asking for stdout in alternate format' do
      api_basic_authorize(subresource_action_identifier(:services, :orchestration_stacks, :read, :get))

      allow_any_instance_of(OrchestrationStack).to receive(:stdout).with("json").and_return("json stdout")
      get(api_service_orchestration_stack_url(nil, svc, os), :params => { :attributes => "stdout", :format_attributes => "stdout=json" })

      expected = {
        'id'     => os.id.to_s,
        'stdout' => "json stdout"
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will not return orchestration stacks without an appropriate role' do
      api_basic_authorize

      get(api_service_orchestration_stacks_url(nil, svc))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'add_resource' do
    let(:vm1) { FactoryGirl.create(:vm_vmware) }
    let(:vm2) { FactoryGirl.create(:vm_vmware) }

    it 'can add vm to services by href with an appropriate role' do
      api_basic_authorize(collection_action_identifier(:services, :add_resource))
      request = {
        'action'    => 'add_resource',
        'resources' => [
          { 'href' => api_service_url(nil, svc), 'resource' => {'href' => api_vm_url(nil, vm1)} },
          { 'href' => api_service_url(nil, svc1), 'resource' => {'href' => api_vm_url(nil, vm2)} }
        ]
      }

      post(api_services_url, :params => request)

      expected = {
        'results' => [
          { 'success' => true, 'message' => "Assigned resource vms id:#{vm1.id} to Service id:#{svc.id} name:'#{svc.name}'"},
          { 'success' => true, 'message' => "Assigned resource vms id:#{vm2.id} to Service id:#{svc1.id} name:'#{svc1.name}'"}
        ]
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(expected)
      expect(svc.reload.vms).to eq([vm1])
      expect(svc1.reload.vms).to eq([vm2])
    end

    it 'returns individual success and failures' do
      user = FactoryGirl.create(:user)
      user.miq_groups << @user.current_group
      api_basic_authorize(collection_action_identifier(:services, :add_resource))
      request = {
        'action'    => 'add_resource',
        'resources' => [
          { 'href' => api_service_url(nil, svc), 'resource' => {'href' => api_vm_url(nil, vm1)} },
          { 'href' => api_service_url(nil, svc1), 'resource' => {'href' => api_user_url(nil, user)} }
        ]
      }

      post(api_services_url, :params => request)

      expected = {
        'results' => [
          { 'success' => true, 'message' => "Assigned resource vms id:#{vm1.id} to Service id:#{svc.id} name:'#{svc.name}'"},
          { 'success' => false, 'message' => "Cannot assign users to Service id:#{svc1.id} name:'#{svc1.name}'"}
        ]
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(expected)
      expect(svc.reload.vms).to eq([vm1])
    end

    it 'requires a valid resource' do
      api_basic_authorize(collection_action_identifier(:services, :add_resource))
      request = {
        'action'   => 'add_resource',
        'resource' => { 'resource' => { 'href' => '1' } }
      }

      post(api_service_url(nil, svc), :params => request)

      expected = { 'success' => false, 'message' => "Invalid resource href specified 1"}

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(expected)
    end

    it 'requires the resource to respond to add_to_service' do
      user = FactoryGirl.create(:user)
      user.miq_groups << @user.current_group
      api_basic_authorize(collection_action_identifier(:services, :add_resource))
      request = {
        'action'   => 'add_resource',
        'resource' => { 'resource' => { 'href' => api_user_url(nil, user) } }
      }

      post(api_service_url(nil, svc), :params => request)

      expected = { 'success' => false, 'message' => "Cannot assign users to Service id:#{svc.id} name:'#{svc.name}'"}

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(expected)
    end

    it 'requires a resource reference' do
      api_basic_authorize(collection_action_identifier(:services, :add_resource))
      request = {
        'action'   => 'add_resource',
        'resource' => { 'resource' => {} }
      }

      post(api_service_url(nil, svc), :params => request)

      expected = { 'success' => false, 'message' => "Must specify a resource reference"}

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(expected)
    end

    it 'can add a vm to a resource with appropriate role' do
      api_basic_authorize(collection_action_identifier(:services, :add_resource))
      request = {
        'action'   => 'add_resource',
        'resource' => { 'resource' => {'href' => api_vm_url(nil, vm1)} }
      }

      post(api_service_url(nil, svc), :params => request)

      expected = { 'success' => true, 'message' => "Assigned resource vms id:#{vm1.id} to Service id:#{svc.id} name:'#{svc.name}'"}

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(expected)
      expect(svc.reload.vms).to eq([vm1])
    end

    it 'cannot add multiple vms to multiple services by href without an appropriate role' do
      api_basic_authorize

      post(api_services_url, :params => { 'action' => 'add_resource' })

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'remove_resource' do
    let(:vm1) { FactoryGirl.create(:vm_vmware) }
    let(:vm2) { FactoryGirl.create(:vm_vmware) }

    before do
      svc.add_resource(vm1)
      svc1.add_resource(vm2)
    end

    it 'cannot remove vms from services without an appropriate role' do
      api_basic_authorize

      post(api_services_url, :params => { 'action' => 'remove_resource' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can remove vms from multiple services by href with an appropriate role' do
      api_basic_authorize collection_action_identifier(:services, :remove_resource)
      request = {
        'action'    => 'remove_resource',
        'resources' => [
          { 'href' => api_service_url(nil, svc), 'resource' => { 'href' => api_vm_url(nil, vm1)} },
          { 'href' => api_service_url(nil, svc1), 'resource' => { 'href' => api_vm_url(nil, vm2)} }
        ]
      }

      post(api_services_url, :params => request)

      expected = {
        'results' => [
          { 'success' => true, 'message' => "Unassigned resource vms id:#{vm1.id} from Service id:#{svc.id} name:'#{svc.name}'" },
          { 'success' => true, 'message' => "Unassigned resource vms id:#{vm2.id} from Service id:#{svc1.id} name:'#{svc1.name}'" }
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(expected)
      expect(svc.reload.service_resources).to eq([])
      expect(svc1.reload.service_resources).to eq([])
    end

    it 'requires a service id to be specified' do
      api_basic_authorize collection_action_identifier(:services, :remove_resource)
      request = {
        'action'    => 'remove_resource',
        'resources' => [
          { 'href' => api_services_url, 'resource' => { 'href' => api_vm_url(nil, vm1)} }
        ]
      }

      post(api_services_url, :params => request)

      expected = {
        'results' => [
          { 'success' => false, 'message' => 'Must specify a resource to remove_resource from' }
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(expected)
    end

    it 'requires that a resource be specified' do
      api_basic_authorize collection_action_identifier(:services, :remove_resource)
      request = {
        'action'    => 'remove_resource',
        'resources' => [
          { 'href' => api_service_url(nil, svc), 'resource' => {} }
        ]
      }

      post(api_services_url, :params => request)

      expected = {
        'results' => [
          { 'success' => false, 'message' => 'Must specify a resource reference' }
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(expected)
    end

    it 'cannot remove a vm from a service without an appropriate role' do
      api_basic_authorize

      post(api_service_url(nil, svc), :params => { 'action' => 'remove_resource' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can remove a vm from a service by href with an appropriate role' do
      api_basic_authorize collection_action_identifier(:services, :remove_resource)
      request = {
        'action'   => 'remove_resource',
        'resource' => { 'resource' => {'href' => api_vm_url(nil, vm1)} }
      }

      post(api_service_url(nil, svc), :params => request)

      expected = {
        'success' => true,
        'message' => "Unassigned resource vms id:#{vm1.id} from Service id:#{svc.id} name:'#{svc.name}'"
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(expected)
      expect(svc.reload.service_resources).to eq([])
    end
  end

  describe 'remove_all_resources' do
    let(:vm1) { FactoryGirl.create(:vm_vmware) }
    let(:vm2) { FactoryGirl.create(:vm_vmware) }
    let(:vm3) { FactoryGirl.create(:vm_vmware) }

    before do
      svc.add_resource(vm1)
      svc.add_resource(vm2)
      svc1.add_resource(vm3)
    end

    it 'cannot remove all resources without an appropriate role' do
      api_basic_authorize

      post(api_services_url, :params => { 'action' => 'remove_all_resources' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can remove all resources from multiple services' do
      api_basic_authorize collection_action_identifier(:services, :remove_all_resources)
      request = {
        'action'    => 'remove_all_resources',
        'resources' => [
          { 'href' => api_service_url(nil, svc) },
          { 'href' => api_service_url(nil, svc1) }
        ]
      }

      post(api_services_url, :params => request)

      expected = {
        'results' => [
          { 'success' => true, 'message' =>  "Removed all resources from Service id:#{svc.id} name:'#{svc.name}'"},
          { 'success' => true, 'message' =>  "Removed all resources from Service id:#{svc1.id} name:'#{svc1.name}'"}
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(expected)
      expect(svc.reload.service_resources).to eq([])
      expect(svc1.reload.service_resources).to eq([])
    end

    it 'cannot remove all resources without an appropriate role' do
      api_basic_authorize

      post(api_service_url(nil, svc), :params => { :action => 'remove_all_resources' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can remove all resources from a service' do
      api_basic_authorize collection_action_identifier(:services, :remove_all_resources)

      post(api_service_url(nil, svc), :params => { :action => 'remove_all_resources' })

      expected = {
        'success' => true, 'message' => "Removed all resources from Service id:#{svc.id} name:'#{svc.name}'"
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(expected)
      expect(svc.reload.service_resources).to eq([])
    end
  end

  describe "Metric Rollups subcollection" do
    let(:url) { api_service_metric_rollups_url(nil, svc) }

    before do
      FactoryGirl.create_list(:metric_rollup_vm_hr, 3, :resource => svc)
      FactoryGirl.create_list(:metric_rollup_vm_daily, 1, :resource => svc)
      FactoryGirl.create_list(:metric_rollup_vm_hr, 1, :resource => svc1)
    end

    it 'returns the metric rollups for the service' do
      api_basic_authorize subcollection_action_identifier(:services, :metric_rollups, :read, :get)

      get(url, :params => { :capture_interval => 'hourly', :start_date => Time.zone.today.to_s })

      expected = {
        'count'    => 5,
        'subcount' => 3,
        'pages'    => 1
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
      expect(response.parsed_body['links'].keys).to match_array(%w(self first last))
    end

    it 'will not return metric rollups without an appropriate role' do
      api_basic_authorize

      get(url, :params => { :capture_interval => 'hourly', :start_date => Time.zone.today.to_s })

      expect(response).to have_http_status(:forbidden)
    end

    it 'does not require resource_type for a subcollection' do
      api_basic_authorize(subcollection_action_identifier(:services, :metric_rollups, :read, :get))

      get(url)

      expected = {
        'error' => a_hash_including(
          'message' => 'Must specify capture_interval, start_date'
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'add_provider_vms_resource' do
    it 'cannot add_provider_vms without an appropriate role' do
      api_basic_authorize

      post(api_service_url(nil, svc), :params => { :action => 'add_provider_vms'})

      expect(response).to have_http_status(:forbidden)
    end

    it 'can add the provider vms to the queue' do
      api_basic_authorize action_identifier(:services, :add_provider_vms)
      svc.update_attributes!(:evm_owner => @user)

      post(api_service_url(nil, svc), :params => { :action => 'add_provider_vms',
                                                   :provider => { :href => api_provider_url(nil, ems) }, :uid_ems => ['uids'] })

      expected = {
        'success'   => true,
        'message'   => a_string_including('Adding provider vms for Service'),
        'task_id'   => a_kind_of(String),
        'task_href' => a_string_including('/api/tasks/')
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires a valid provider href' do
      api_basic_authorize action_identifier(:services, :add_provider_vms)

      post(api_service_url(nil, svc), :params => { :action  => 'add_provider_vms',
                                                   :uid_ems => ['uids'] })

      expected = {
        'success' => false,
        'message' => a_string_including('Must specify a valid provider href or id')
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires provider hash to be passed with id or href' do
      api_basic_authorize action_identifier(:services, :add_provider_vms)

      post(api_service_url(nil, svc), :params => { :action   => 'add_provider_vms',
                                                   :uid_ems  => ['uids'],
                                                   :provider => 'api/providers/:id'})

      expected = {
        'success' => false,
        'message' => a_string_including('Must specify a valid provider href or id')
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can bulk add_provider_vms' do
      api_basic_authorize action_identifier(:services, :add_provider_vms)
      svc.update_attributes!(:evm_owner => @user)
      svc2.update_attributes!(:evm_owner => @user)

      post(api_services_url, :params => { :action    => 'add_provider_vms',
                                          :resources => [
                                            { :href => api_service_url(nil, svc), :provider => { :href => api_provider_url(nil, ems) }, :uid_ems => ['uids'] },
                                            { :href => api_service_url(nil, svc2), :provider => { :href => api_provider_url(nil, ems) }, :uid_ems => ['uids']}
                                          ]})

      expected = {
        'results' => [
          {'success' => true, 'message' => a_string_including("Adding provider vms for Service id:#{svc.id}"), 'task_id' => a_kind_of(String), 'task_href' => a_string_including(api_tasks_url)},
          {'success' => true, 'message' => a_string_including("Adding provider vms for Service id:#{svc2.id}"), 'task_id' => a_kind_of(String), 'task_href' => a_string_including(api_tasks_url)},
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Generic Objects Subcollection" do
    let(:content) do
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABGdBTUEAALGP"\
      "C/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3Cc"\
      "ulE8AAAACXBIWXMAAAsTAAALEwEAmpwYAAABWWlUWHRYTUw6Y29tLmFkb2Jl"\
      "LnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIg"\
      "eDp4bXB0az0iWE1QIENvcmUgNS40LjAiPgogICA8cmRmOlJERiB4bWxuczpy"\
      "ZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1u"\
      "cyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAg"\
      "ICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYv"\
      "MS4wLyI+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3Jp"\
      "ZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpS"\
      "REY+CjwveDp4bXBtZXRhPgpMwidZAAAADUlEQVQIHWNgYGCwBQAAQgA+3N0+"\
      "xQAAAABJRU5ErkJggg=="
    end
    let(:picture) { FactoryGirl.create(:picture, :content => content) }
    let(:generic_object_definition) { FactoryGirl.create(:generic_object_definition, :picture => picture) }
    let(:generic_object) { FactoryGirl.create(:generic_object, :generic_object_definition => generic_object_definition) }

    before do
      svc.add_resource(generic_object)
      svc.save!
    end

    it "returns generic objects associatied with a service" do
      api_basic_authorize subcollection_action_identifier(:services, :generic_objects, :read, :get)

      get(api_service_generic_objects_url(nil, svc))

      expected = {
        'name'      => 'generic_objects',
        'resources' => [
          { 'href' => api_service_generic_object_url(nil, svc, generic_object) }
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "does not return a service's generic objects without an appropriate role" do
      api_basic_authorize

      get(api_service_generic_objects_url(nil, svc))

      expect(response).to have_http_status(:forbidden)
    end

    it "allows expansion of generic objects and specification of generic object attributes" do
      api_basic_authorize(action_identifier(:services, :read, :resource_actions, :get))

      get api_services_url, :params => { :expand => 'resources,generic_objects', :attributes => 'generic_objects.generic_object_definition,generic_objects.picture,generic_objects.href_slug' }

      expected = {
        'name'      => 'services',
        'count'     => 1,
        'subcount'  => 1,
        'resources' => [
          a_hash_including(
            'href'            => api_service_url(nil, svc),
            'generic_objects' => [
              a_hash_including(
                'href'                      => api_service_generic_object_url(nil, svc, generic_object),
                'generic_object_definition' => a_hash_including('id' => generic_object_definition.id.to_s),
                'picture'                   => a_hash_including('image_href' => a_string_including(picture.image_href), 'extension' => picture.extension),
                'href_slug'                 => "generic_objects/#{generic_object.id}"
              )
            ]
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "does not return invalid actions" do
      api_basic_authorize(subcollection_action_identifier(:services, :generic_objects, :read, :get),
                          collection_action_identifier(:generic_objects, :create))

      get(api_service_generic_objects_url(nil, svc))

      expect(response.parsed_body.key?('actions')).to be_falsey
    end
  end

  context "service custom_attributes" do
    let(:service_url) { api_service_url(nil, svc) }
    let(:ca1) { FactoryGirl.create(:custom_attribute, :name => "name1", :value => "value1") }
    let(:ca2) { FactoryGirl.create(:custom_attribute, :name => "name2", :value => "value2") }
    let(:ca1_url)        { api_service_custom_attribute_url(nil, svc, ca1) }
    let(:ca2_url)        { api_service_custom_attribute_url(nil, svc, ca2) }

    it "getting custom_attributes from a service with no custom_attributes" do
      api_basic_authorize

      get(api_service_custom_attributes_url(nil, svc))

      expect_empty_query_result(:custom_attributes)
    end

    it "getting custom_attributes from a service" do
      api_basic_authorize
      svc.custom_attributes = [ca1, ca2]

      get api_service_custom_attributes_url(nil, svc)

      expect_query_result(:custom_attributes, 2)
      expect_result_resources_to_include_hrefs("resources",
                                               [api_service_custom_attribute_url(nil, svc, ca1),
                                                api_service_custom_attribute_url(nil, svc, ca2)])
    end

    it "getting custom_attributes from a service in expanded form" do
      api_basic_authorize
      svc.custom_attributes = [ca1, ca2]

      get api_service_custom_attributes_url(nil, svc), :params => { :expand => "resources" }

      expect_query_result(:custom_attributes, 2)
      expect_result_resources_to_include_data("resources", "name" => %w(name1 name2))
    end

    it "getting custom_attributes from a service using expand" do
      api_basic_authorize action_identifier(:services, :read, :resource_actions, :get)
      svc.custom_attributes = [ca1, ca2]

      get service_url, :params => { :expand => "custom_attributes" }

      expect_single_resource_query("id" => svc.id.to_s)
      expect_result_resources_to_include_data("custom_attributes", "name" => %w(name1 name2))
    end

    it "delete a custom_attribute without appropriate role" do
      api_basic_authorize
      svc.custom_attributes = [ca1]

      post(api_service_custom_attributes_url(nil, svc), :params => gen_request(:delete, nil, service_url))

      expect(response).to have_http_status(:forbidden)
    end

    it "delete a custom_attribute from a service via the delete action" do
      api_basic_authorize subcollection_action_identifier(:services, :custom_attributes, :delete)
      svc.custom_attributes = [ca1]

      post(api_service_custom_attributes_url(nil, svc), :params => gen_request(:delete, nil, ca1_url))

      expect(response).to have_http_status(:ok)
      expect(svc.reload.custom_attributes).to be_empty
    end

    it "add custom attribute to a service without a name" do
      api_basic_authorize subcollection_action_identifier(:services, :custom_attributes, :edit)

      post(api_service_custom_attributes_url(nil, svc), :params => gen_request(:add, "value" => "value1"))

      expect_bad_request("Must specify a name")
    end

    it "add custom attributes to a service" do
      api_basic_authorize subcollection_action_identifier(:services, :custom_attributes, :edit)

      post(api_service_custom_attributes_url(nil, svc),
           :params => gen_request(:add, [{"name" => "name1", "value" => "value1"},
                                         {"name" => "name2", "value" => "value2"}]))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_data("results", "name" => %w(name1 name2))
      expect(svc.custom_attributes.size).to eq(2)
      expect(svc.custom_attributes.pluck(:value).sort).to eq(%w(value1 value2))
    end

    it "edit a custom attribute by name" do
      api_basic_authorize subcollection_action_identifier(:services, :custom_attributes, :edit)
      svc.custom_attributes = [ca1]

      post(api_service_custom_attributes_url(nil, svc), :params => gen_request(:edit, "name" => "name1", "value" => "value one"))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_data("results", "value" => ["value one"])
      expect(svc.reload.custom_attributes.first.value).to eq("value one")
    end

    it "edit a custom attribute by href" do
      api_basic_authorize subcollection_action_identifier(:services, :custom_attributes, :edit)
      svc.custom_attributes = [ca1]

      post(api_service_custom_attributes_url(nil, svc), :params => gen_request(:edit, "href" => ca1_url, "value" => "new value1"))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_data("results", "value" => ["new value1"])
      expect(svc.reload.custom_attributes.first.value).to eq("new value1")
    end

    it "edit multiple custom attributes" do
      api_basic_authorize subcollection_action_identifier(:services, :custom_attributes, :edit)
      svc.custom_attributes = [ca1, ca2]

      post(api_service_custom_attributes_url(nil, svc),
           :params => gen_request(:edit, [{"name" => "name1", "value" => "new value1"},
                                          {"name" => "name2", "value" => "new value2"}]))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_data("results", "value" => ["new value1", "new value2"])
      expect(svc.reload.custom_attributes.pluck(:value).sort).to eq(["new value1", "new value2"])
    end
  end

  describe 'queue_chargeback_report' do
    it 'will not queue chargeback without an appropriate role' do
      api_basic_authorize

      post(api_services_url, :params => {:action => 'queue_chargeback_report', :resource => 'all'})

      expect(response).to have_http_status(:forbidden)
    end

    it 'can queue chargeback reports for multiple resources' do
      api_basic_authorize collection_action_identifier(:services, :queue_chargeback_report)

      post(api_services_url, :params => {:action => 'queue_chargeback_report', :resources => [{:id => svc1.id}, {:href => api_service_url(nil, svc2)}]})

      expected = {
        'results' => [a_hash_including('success' => true, 'message' => /Queued chargeback report generation for Service/, 'task_href' => a_string_including(api_tasks_url)),
                      a_hash_including('success' => true, 'message' => /Queued chargeback report generation for Service/, 'task_href' => a_string_including(api_tasks_url))]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can queue chargeback report for a single resource' do
      api_basic_authorize action_identifier(:services, :queue_chargeback_report)

      post(api_service_url(nil, svc1), :params => {:action => 'queue_chargeback_report'})

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('success' => true, 'message' => /Queued chargeback report generation for Service/, 'task_id' => a_kind_of(String))
    end

    it 'will not queue chargeback report for a resource without an appropriate role' do
      api_basic_authorize

      post(api_service_url(nil, svc1), :params => { :action => 'queue_chargeback_report' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can queue chargeback report for the current user' do
      api_basic_authorize action_identifier(:services, :queue_chargeback_report)

      post(api_service_url(nil, svc1), :params => {:action => 'queue_chargeback_report'})

      expect(response).to have_http_status(:ok)

      q = MiqQueue.where(:class_name  => "Service", :method_name => "generate_chargeback_report").take
      expect(q.args).to eq([{:userid=>"api_user_id"}])
    end
  end
end
