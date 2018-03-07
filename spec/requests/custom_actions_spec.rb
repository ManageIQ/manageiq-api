#
# Rest API Request Tests - Custom Actions
#
# - Querying custom actions and custom action buttons of service templates
#       GET /api/service_templates/:id?attributes=custom_actions
#       GET /api/service_templates/:id?attributes=custom_action_buttons
#
# - Querying custom actions and custom action buttons of services
#       GET /api/services/:id?attributes=custom_actions
#       GET /api/services/:id?attributes=custom_action_buttons
#
# - Querying a service should also return in its actions the list
#   of custom actions.
#       GET /api/services/:id
#
# - Triggering a custom action on a service (case insensitive)
#       POST /api/services/:id
#          { "action" : "<custom_action_button_name>" }
#
describe "Custom Actions API" do
  let(:template1) { FactoryGirl.create(:service_template, :name => "template1") }
  let(:svc1) { FactoryGirl.create(:service, :name => "svc1", :service_template_id => template1.id) }

  let(:button1) do
    FactoryGirl.create(:custom_button,
                       :name        => "button1",
                       :description => "button one",
                       :applies_to  => template1,
                       :userid      => @user.userid)
  end

  let(:button2) do
    FactoryGirl.create(:custom_button,
                       :name        => "button2",
                       :description => "button two",
                       :applies_to  => template1,
                       :userid      => @user.userid)
  end

  let(:button3) do
    FactoryGirl.create(:custom_button,
                       :name        => "button3",
                       :description => "button three",
                       :applies_to  => template1,
                       :userid      => @user.userid)
  end

  let(:button_group1) do
    FactoryGirl.create(:custom_button_set,
                       :name        => "button_group1",
                       :description => "button group one",
                       :set_data    => {:applies_to_id => template1.id, :applies_to_class => template1.class.name},
                       :owner       => template1)
  end

  def create_custom_buttons
    button1
    button_group1.replace_children([button2, button3])
  end

  def expect_result_to_have_custom_actions_hash
    expect_result_to_have_keys(%w(custom_actions))
    custom_actions = response.parsed_body["custom_actions"]
    expect_hash_to_have_only_keys(custom_actions, %w(buttons button_groups))
    expect(custom_actions["buttons"].size).to eq(1)
    expect(custom_actions["button_groups"].size).to eq(1)
    expect(custom_actions["button_groups"].first["buttons"].size).to eq(2)
  end

  describe "Querying services with no custom actions" do
    let(:service) { FactoryGirl.create(:service) }

    it "returns core actions as authorized" do
      api_basic_authorize(action_identifier(:services, :edit),
                          action_identifier(:services, :read, :resource_actions, :get))

      get api_service_url(nil, svc1)

      expect_result_to_have_keys(%w(id href actions))
      expect(response.parsed_body["actions"].select { |a| a["method"] == "post" }.pluck("name")).to match_array(%w(edit add_resource remove_resource remove_all_resources add_provider_vms))
    end

    it "allows expanding of custom actions" do
      api_basic_authorize(collection_action_identifier(:services, :read, :get))

      expected = { 'resources' => [a_hash_including('id' => service.id.to_s)] }
      get(api_services_url, :params => { :expand => "resources", :attributes => "custom_actions" })

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Querying services with custom actions" do
    before(:each) do
      create_custom_buttons
    end

    it "returns core actions as authorized including custom action buttons" do
      api_basic_authorize(action_identifier(:services, :edit),
                          action_identifier(:services, :read, :resource_actions, :get))

      get api_service_url(nil, svc1)

      expect_result_to_have_keys(%w(id href actions))
      expect(response.parsed_body["actions"].select { |a| a["method"] == "post" }.pluck("name")).to match_array(%w(edit button1 button2 button3 add_resource remove_resource remove_all_resources add_provider_vms))
    end

    it "do not return custom actions when querying the collection" do
      api_basic_authorize(action_identifier(:services, :edit),
                          action_identifier(:services, :read, :resource_actions, :get))

      svc1 # create service
      get api_services_url, :params => { :expand => "resources" }

      expected = {
        "count"     => 1,
        "name"      => "services",
        "subcount"  => 1,
        "resources" => [
          a_hash_including("id" => svc1.id.to_s, "href" => api_service_url(nil, svc1), "actions" => a_hash_including(anything))
        ]
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
      actions = response.parsed_body["resources"].first["actions"]
      expect(actions.pluck("name") & %w(button1 button2 button3)).to be_empty
    end

    it "supports the custom_actions attribute" do
      api_basic_authorize(action_identifier(:services, :edit),
                          action_identifier(:services, :read, :resource_actions, :get))

      get api_service_url(nil, svc1), :params => { :attributes => "custom_actions" }

      expect_result_to_have_keys(%w(id href))
      expect_result_to_have_custom_actions_hash
    end

    it "supports the custom_action_buttons attribute" do
      api_basic_authorize(action_identifier(:services, :edit),
                          action_identifier(:services, :read, :resource_actions, :get))

      get api_service_url(nil, svc1), :params => { :attributes => "custom_action_buttons" }

      expect_result_to_have_keys(%w(id href custom_action_buttons))
      expect(response.parsed_body["custom_action_buttons"].size).to eq(3)
    end
  end

  describe "Querying service_templates with custom actions" do
    before(:each) do
      create_custom_buttons
    end

    it "returns core actions as authorized excluding custom action buttons" do
      api_basic_authorize(action_identifier(:service_templates, :edit),
                          action_identifier(:service_templates, :read, :resource_actions, :get))

      get api_service_template_url(nil, template1)

      expect_result_to_have_keys(%w(id href actions))
      action_specs = response.parsed_body["actions"]
      expect(action_specs.size).to eq(3)
      expect(action_specs.first["name"]).to eq("edit")
    end

    it "supports the custom_actions attribute" do
      api_basic_authorize action_identifier(:service_templates, :read, :resource_actions, :get)

      get api_service_template_url(nil, template1), :params => { :attributes => "custom_actions" }

      expect_result_to_have_keys(%w(id href))
      expect_result_to_have_custom_actions_hash
    end

    it "supports the custom_action_buttons attribute" do
      api_basic_authorize action_identifier(:service_templates, :read, :resource_actions, :get)

      get api_service_template_url(nil, template1), :params => { :attributes => "custom_action_buttons" }

      expect_result_to_have_keys(%w(id href custom_action_buttons))
      expect(response.parsed_body["custom_action_buttons"].size).to eq(3)
    end
  end

  describe "Services with custom actions" do
    before(:each) do
      create_custom_buttons
      button1.resource_action = FactoryGirl.create(:resource_action)
    end

    it "accepts a custom action" do
      api_basic_authorize

      post(api_service_url(nil, svc1), :params => gen_request(:button1, "button_key1" => "value", "button_key2" => "value"))

      expect_single_action_result(:success => true, :message => /.*/, :href => api_service_url(nil, svc1))
    end

    it "accepts a custom action as case insensitive" do
      api_basic_authorize

      post(api_service_url(nil, svc1), :params => gen_request(:BuTtOn1, "button_key1" => "value", "button_key2" => "value"))

      expect_single_action_result(:success => true, :message => /.*/, :href => api_service_url(nil, svc1))
    end
  end

  describe "Services with grouped generic custom buttons" do
    it "accepts a custom action" do
      button = FactoryGirl.create(
        :custom_button,
        :name             => "test button",
        :applies_to_class => "Service",
        :resource_action  => FactoryGirl.create(:resource_action)
      )
      button_group = FactoryGirl.create(:custom_button_set)
      button_group.add_member(button)
      service = FactoryGirl.create(:service, :service_template => FactoryGirl.create(:service_template))
      api_basic_authorize

      post(api_service_url(nil, service), :params => { "action" => "test button" })

      expect(response.parsed_body).to include("success" => true, "message" => /Invoked custom action test button/)
    end
  end

  describe "Services with custom button dialogs" do
    it "queries for custom_actions returns expanded details for dialog buttons" do
      api_basic_authorize action_identifier(:services, :read, :resource_actions, :get)

      template2 = FactoryGirl.create(:service_template, :name => "template2")
      dialog2   = FactoryGirl.create(:dialog, :label => "dialog2")
      ra2       = FactoryGirl.create(:resource_action, :dialog_id => dialog2.id)
      button2   = FactoryGirl.create(:custom_button, :applies_to => template2, :userid => @user.userid)
      svc2      = FactoryGirl.create(:service, :name => "svc2", :service_template_id => template2.id)
      button2.resource_action = ra2

      get api_service_url(nil, svc2), :params => { :attributes => "custom_actions" }

      expected = {
        "custom_actions" => {
          "button_groups" => anything,
          "buttons"       => [
            hash_including(
              "id"              => anything,
              "resource_action" => hash_including("id" => ra2.id.to_s, "dialog_id" => ra2.dialog.id.to_s)
            )
          ]
        }
      }
      expect(response.parsed_body).to include(expected)
    end
  end

  def define_custom_button1(resource)
    FactoryGirl.create(:custom_button, :with_resource_action_dialog, :applies_to => resource)
  end

  describe "CloudTenant" do
    before do
      @resource = FactoryGirl.create(:cloud_tenant)
      @button1 = define_custom_button1(@resource)
    end

    it "queries return custom actions defined" do
      api_basic_authorize(action_identifier(:cloud_tenants, :read, :resource_actions, :get))

      get api_cloud_tenant_url(nil, @resource)

      expect(response.parsed_body).to include(
        "id"      => @resource.id.to_s,
        "href"    => api_cloud_tenant_url(nil, @resource),
        "actions" => a_collection_including(a_hash_including("name" => @button1.name))
      )
    end

    it "accepts custom actions" do
      api_basic_authorize

      post api_cloud_tenant_url(nil, @resource), :params => gen_request(@button1.name.to_sym, "key1" => "value1")

      expect_single_action_result(:success => true, :message => /.*/, :href => api_cloud_tenant_url(nil, @resource))
    end
  end

  describe "Clusters" do
    before do
      @zone = FactoryGirl.create(:zone, :name => "api_zone")
      @provider = FactoryGirl.create(:ems_vmware, :zone => @zone)
      @resource = FactoryGirl.create(:ems_cluster, :ext_management_system => @provider)
      @button1 = define_custom_button1(@resource)
    end

    it "queries return custom actions defined" do
      api_basic_authorize(action_identifier(:clusters, :read, :resource_actions, :get))

      get api_cluster_url(nil, @resource)

      expect(response.parsed_body).to include(
        "id"      => @resource.id.to_s,
        "href"    => api_cluster_url(nil, @resource),
        "actions" => a_collection_including(a_hash_including("name" => @button1.name))
      )
    end

    it "accepts custom actions" do
      api_basic_authorize

      post api_cluster_url(nil, @resource), :params => gen_request(@button1.name.to_sym, "key1" => "value1")

      expect_single_action_result(:success => true, :message => /.*/, :href => api_cluster_url(nil, @resource))
    end
  end

  describe "ContainerNode" do
    before do
      @resource = FactoryGirl.create(:container_node)
      @button1 = define_custom_button1(@resource)
    end

    it "queries return custom actions defined" do
      api_basic_authorize(action_identifier(:container_nodes, :read, :resource_actions, :get))

      get api_container_node_url(nil, @resource)

      expect(response.parsed_body).to include(
        "id"      => @resource.id.to_s,
        "href"    => api_container_node_url(nil, @resource),
        "actions" => a_collection_including(a_hash_including("name" => @button1.name))
      )
    end

    it "accepts custom actions" do
      api_basic_authorize

      post api_container_node_url(nil, @resource), :params => gen_request(@button1.name.to_sym, "key1" => "value1")

      expect_single_action_result(:success => true, :message => /.*/, :href => api_container_node_url(nil, @resource))
    end
  end

  describe "ContainerProjects" do
    before do
      @resource = FactoryGirl.create(:container_project)
      @button = define_custom_button1(@resource)
    end

    it "queries return custom actions defined" do
      api_basic_authorize(action_identifier(:container_projects, :read, :resource_actions, :get))

      get(api_container_project_url(nil, @resource))

      expect(response.parsed_body).to include(
        "id"      => @resource.id.to_s,
        "href"    => api_container_project_url(nil, @resource),
        "actions" => a_collection_including(a_hash_including("name" => @button.name))
      )
    end

    it "accept custom actions" do
      api_basic_authorize

      post(api_container_project_url(nil, @resource), :params => gen_request(@button.name, "key1" => "value1"))

      expect_single_action_result(:success => true, :message => /.*/, :href => api_container_project_url(nil, @resource))
    end
  end

  describe "Generic Objects" do
    before do
      @object_definition = FactoryGirl.create(:generic_object_definition, :name => 'object def')
      @resource = FactoryGirl.create(:generic_object, :generic_object_definition => @object_definition)
      @button = define_custom_button1(@object_definition)
    end

    it "queries return custom actions and property methods defined" do
      @object_definition.add_property_method("a_property_method")
      api_basic_authorize(action_identifier(:generic_objects, :read, :resource_actions, :get))

      get api_generic_object_url(nil, @resource)

      expect(response.parsed_body).to include(
        "id"      => @resource.id.to_s,
        "href"    => api_generic_object_url(nil, @resource),
        "actions" => a_collection_including(a_hash_including("name" => @button.name), a_hash_including("name" => "a_property_method"))
      )
    end

    it "accept custom actions" do
      api_basic_authorize

      post api_generic_object_url(nil, @resource), :params => gen_request(@button.name, "key1" => "value1")

      expect_single_action_result(:success => true, :message => /.*/, :href => api_generic_object_url(nil, @resource))
    end
  end

  describe "Host" do
    before do
      @resource = FactoryGirl.create(:host)
      @button1 = define_custom_button1(@resource)
    end

    it "queries return custom actions defined" do
      api_basic_authorize(action_identifier(:hosts, :read, :resource_actions, :get))

      get api_host_url(nil, @resource)

      expect(response.parsed_body).to include(
        "id"      => @resource.id.to_s,
        "href"    => api_host_url(nil, @resource),
        "actions" => a_collection_including(a_hash_including("name" => @button1.name))
      )
    end

    it "accepts custom actions" do
      api_basic_authorize

      post api_host_url(nil, @resource), :params => gen_request(@button1.name.to_sym, "key1" => "value1")

      expect_single_action_result(:success => true, :message => /.*/, :href => api_host_url(nil, @resource))
    end
  end

  describe "Providers" do
    before do
      @resource = FactoryGirl.create(:ext_management_system)
      @button1 = define_custom_button1(@resource)
    end

    it "queries return custom actions defined" do
      api_basic_authorize(action_identifier(:providers, :read, :resource_actions, :get))

      get api_provider_url(nil, @resource)

      expect(response.parsed_body).to include(
        "id"      => @resource.id.to_s,
        "href"    => api_provider_url(nil, @resource),
        "actions" => a_collection_including(a_hash_including("name" => @button1.name))
      )
    end

    it "accepts custom actions" do
      api_basic_authorize

      post api_provider_url(nil, @resource), :params => gen_request(@button1.name.to_sym, "key1" => "value1")

      expect_single_action_result(:success => true, :message => /.*/, :href => api_provider_url(nil, @resource))
    end
  end

  describe "Storage" do
    before do
      @resource = FactoryGirl.create(:storage)
      @button1 = define_custom_button1(@resource)
    end

    it "queries return custom actions defined" do
      api_basic_authorize(action_identifier(:data_stores, :read, :resource_actions, :get))

      get api_data_store_url(nil, @resource)

      expect(response.parsed_body).to include(
        "id"      => @resource.id.to_s,
        "href"    => api_data_store_url(nil, @resource),
        "actions" => a_collection_including(a_hash_including("name" => @button1.name))
      )
    end

    it "accepts custom actions" do
      api_basic_authorize

      post api_data_store_url(nil, @resource), :params => gen_request(@button1.name.to_sym, "key1" => "value1")

      expect_single_action_result(:success => true, :message => /.*/, :href => api_data_store_url(nil, @resource))
    end
  end

  describe "Template" do
    before do
      @resource = FactoryGirl.create(:miq_template)
      @button1 = define_custom_button1(@resource)
    end

    it "queries return custom actions defined" do
      api_basic_authorize(action_identifier(:templates, :read, :resource_actions, :get))

      get api_template_url(nil, @resource)

      expect(response.parsed_body).to include(
        "id"      => @resource.id.to_s,
        "href"    => api_template_url(nil, @resource),
        "actions" => a_collection_including(a_hash_including("name" => @button1.name))
      )
    end

    it "accepts custom actions" do
      api_basic_authorize

      post api_template_url(nil, @resource), :params => gen_request(@button1.name.to_sym, "key1" => "value1")

      expect_single_action_result(:success => true, :message => /.*/, :href => api_template_url(nil, @resource))
    end
  end

  describe "Vms" do
    before do
      @resource = FactoryGirl.create(:vm)
      @button1 = define_custom_button1(@resource)
    end

    it "queries return custom actions defined" do
      api_basic_authorize(action_identifier(:vms, :read, :resource_actions, :get))

      get api_vm_url(nil, @resource)

      expect(response.parsed_body).to include(
        "id"      => @resource.id.to_s,
        "href"    => api_vm_url(nil, @resource),
        "actions" => a_collection_including(a_hash_including("name" => @button1.name))
      )
    end

    it "accepts custom actions" do
      api_basic_authorize

      post api_vm_url(nil, @resource), :params => gen_request(@button1.name.to_sym, "key1" => "value1")

      expect_single_action_result(:success => true, :message => /.*/, :href => api_vm_url(nil, @resource))
    end
  end
<<<<<<< HEAD
=======

  describe "User" do
    before do
      @resource = FactoryGirl.create(:user)
      @button1 = define_custom_button1(@resource)
      @resource.miq_groups << @user.current_group
    end

    it "queries return custom actions defined" do
      api_basic_authorize(action_identifier(:users, :read, :resource_actions, :get))

      get api_user_url(nil, @resource)

      expect(response.parsed_body).to include(
        "id"      => @resource.id.to_s,
        "href"    => api_user_url(nil, @resource),
        "actions" => a_collection_including(a_hash_including("name" => @button1.name))
      )
    end

    it "accepts custom actions" do
      api_basic_authorize

      post api_user_url(nil, @resource), :params => gen_request(@button1.name.to_sym, "key1" => "value1")

      expect_single_action_result(:success => true, :message => /.*/, :href => api_user_url(nil, @resource))
    end
  end
>>>>>>> a2895f0... Merge pull request #340 from jntullo/fix_rbac_spec_fixes
end
