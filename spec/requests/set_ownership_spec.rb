#
# Rest API Request Tests - set_ownership action specs
#
# set_ownership action availability to:
# - Services                /api/services/:id
# - Vms                     /api/vms/:id
# - Templates               /api/templates/:id
#
describe "Set Ownership" do
  def expect_set_ownership_success(object, href, user = nil, group = nil)
    expect_single_action_result(:success => true, :message => "setting ownership", :href => href)
    expect(object.reload.evm_owner).to eq(user)  if user
    expect(object.reload.miq_group).to eq(group) if group
  end

  context "Service set_ownership action" do
    let(:svc) { FactoryBot.create(:service, :name => "svc", :description => "svc description") }

    it "to an invalid service" do
      api_basic_authorize action_identifier(:services, :set_ownership)

      post(api_service_url(nil, 999_999), :params => gen_request(:set_ownership, "owner" => {"id" => 1}))

      expect(response).to have_http_status(:not_found)
    end

    it "without appropriate action role" do
      api_basic_authorize

      post(api_service_url(nil, svc), :params => gen_request(:set_ownership, "owner" => {"id" => 1}))

      expect(response).to have_http_status(:forbidden)
    end

    it "with missing owner or group" do
      api_basic_authorize action_identifier(:services, :set_ownership)

      post(api_service_url(nil, svc), :params => gen_request(:set_ownership))

      expect_bad_request("Must specify an owner or group")
    end

    it "with invalid owner" do
      api_basic_authorize action_identifier(:services, :set_ownership)

      post(api_service_url(nil, svc), :params => gen_request(:set_ownership, "owner" => {"id" => 999_999}))

      expect_single_action_result(:success => false, :message => /.*/, :href => api_service_url(nil, svc))
    end

    it "to a service" do
      api_basic_authorize action_identifier(:services, :set_ownership)

      post(api_service_url(nil, svc), :params => gen_request(:set_ownership, "owner" => {"userid" => @user.userid}))

      expect_set_ownership_success(svc, api_service_url(nil, svc), @user)
    end

    it "by owner name to a service" do
      api_basic_authorize action_identifier(:services, :set_ownership)

      post(api_service_url(nil, svc), :params => gen_request(:set_ownership, "owner" => {"name" => @user.name}))

      expect_set_ownership_success(svc, api_service_url(nil, svc), @user)
    end

    it "by owner href to a service" do
      api_basic_authorize action_identifier(:services, :set_ownership)

      post(api_service_url(nil, svc), :params => gen_request(:set_ownership, "owner" => {"href" => api_user_url(nil, @user)}))

      expect_set_ownership_success(svc, api_service_url(nil, svc), @user)
    end

    it "by owner id to a service" do
      api_basic_authorize action_identifier(:services, :set_ownership)

      post(api_service_url(nil, svc), :params => gen_request(:set_ownership, "owner" => {"id" => @user.id}))

      expect_set_ownership_success(svc, api_service_url(nil, svc), @user)
    end

    it "by group id to a service" do
      api_basic_authorize action_identifier(:services, :set_ownership)

      post(api_service_url(nil, svc), :params => gen_request(:set_ownership, "group" => {"id" => @group.id}))

      expect_set_ownership_success(svc, api_service_url(nil, svc), nil, @group)
    end

    it "by group description to a service" do
      api_basic_authorize action_identifier(:services, :set_ownership)

      post(api_service_url(nil, svc), :params => gen_request(:set_ownership, "group" => {"description" => @group.description}))

      expect_set_ownership_success(svc, api_service_url(nil, svc), nil, @group)
    end

    it "with owner and group to a service" do
      api_basic_authorize action_identifier(:services, :set_ownership)

      post(api_service_url(nil, svc), :params => gen_request(:set_ownership, "owner" => {"userid" => @user.userid}))

      expect_set_ownership_success(svc, api_service_url(nil, svc), @user)
    end

    it "to multiple services" do
      api_basic_authorize action_identifier(:services, :set_ownership)

      svc1 = FactoryBot.create(:service, :name => "svc1", :description => "svc1 description")
      svc2 = FactoryBot.create(:service, :name => "svc2", :description => "svc2 description")

      svc_urls = [api_service_url(nil, svc1), api_service_url(nil, svc2)]
      post(api_services_url, :params => gen_request(:set_ownership, {"owner" => {"userid" => @user.userid}}, *svc_urls))

      expect_multiple_action_result(2)
      expect_result_resources_to_include_hrefs("results", [api_service_url(nil, svc1), api_service_url(nil, svc2)])
      expect(svc1.reload.evm_owner).to eq(@user)
      expect(svc2.reload.evm_owner).to eq(@user)
    end
  end

  context "Vms set_ownership action" do
    let(:vm) { FactoryBot.create(:vm, :name => "vm", :description => "vm description") }

    it "to an invalid vm" do
      api_basic_authorize action_identifier(:vms, :set_ownership)

      post(api_vm_url(nil, 999_999), :params => gen_request(:set_ownership, "owner" => {"id" => 1}))

      expect(response).to have_http_status(:not_found)
    end

    it "without appropriate action role" do
      api_basic_authorize

      post(api_vm_url(nil, vm), :params => gen_request(:set_ownership, "owner" => {"id" => 1}))

      expect(response).to have_http_status(:forbidden)
    end

    it "with missing owner or group" do
      api_basic_authorize action_identifier(:vms, :set_ownership)

      post(api_vm_url(nil, vm), :params => gen_request(:set_ownership))

      expect_bad_request("Must specify an owner or group")
    end

    it "with invalid owner" do
      api_basic_authorize action_identifier(:vms, :set_ownership)

      post(api_vm_url(nil, vm), :params => gen_request(:set_ownership, "owner" => {"id" => 999_999}))

      expect_single_action_result(:success => false, :message => /.*/, :href => api_vm_url(nil, vm))
    end

    it "to a vm" do
      api_basic_authorize action_identifier(:vms, :set_ownership)

      post(api_vm_url(nil, vm), :params => gen_request(:set_ownership, "owner" => {"userid" => @user.userid}))

      expect_set_ownership_success(vm, api_vm_url(nil, vm), @user)
    end

    it "by owner name to a vm" do
      api_basic_authorize action_identifier(:vms, :set_ownership)

      post(api_vm_url(nil, vm), :params => gen_request(:set_ownership, "owner" => {"name" => @user.name}))

      expect_set_ownership_success(vm, api_vm_url(nil, vm), @user)
    end

    it "by owner href to a vm" do
      api_basic_authorize action_identifier(:vms, :set_ownership)

      post(api_vm_url(nil, vm), :params => gen_request(:set_ownership, "owner" => {"href" => api_user_url(nil, @user)}))

      expect_set_ownership_success(vm, api_vm_url(nil, vm), @user)
    end

    it "by owner id to a vm" do
      api_basic_authorize action_identifier(:vms, :set_ownership)

      post(api_vm_url(nil, vm), :params => gen_request(:set_ownership, "owner" => {"id" => @user.id}))

      expect_set_ownership_success(vm, api_vm_url(nil, vm), @user)
    end

    it "by group id to a vm" do
      api_basic_authorize action_identifier(:vms, :set_ownership)

      post(api_vm_url(nil, vm), :params => gen_request(:set_ownership, "group" => {"id" => @group.id}))

      expect_set_ownership_success(vm, api_vm_url(nil, vm), nil, @group)
    end

    it "by group description to a vm" do
      api_basic_authorize action_identifier(:vms, :set_ownership)

      post(api_vm_url(nil, vm), :params => gen_request(:set_ownership, "group" => {"description" => @group.description}))

      expect_set_ownership_success(vm, api_vm_url(nil, vm), nil, @group)
    end

    it "with owner and group to a vm" do
      api_basic_authorize action_identifier(:vms, :set_ownership)

      post(api_vm_url(nil, vm), :params => gen_request(:set_ownership, "owner" => {"userid" => @user.userid}))

      expect_set_ownership_success(vm, api_vm_url(nil, vm), @user)
    end

    it "to multiple vms" do
      api_basic_authorize action_identifier(:vms, :set_ownership)

      vm1 = FactoryBot.create(:vm, :name => "vm1", :description => "vm1 description")
      vm2 = FactoryBot.create(:vm, :name => "vm2", :description => "vm2 description")

      vm_urls = [api_vm_url(nil, vm1), api_vm_url(nil, vm2)]
      post(api_vms_url, :params => gen_request(:set_ownership, {"owner" => {"userid" => @user.userid}}, *vm_urls))

      expect_multiple_action_result(2)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
      expect(vm1.reload.evm_owner).to eq(@user)
      expect(vm2.reload.evm_owner).to eq(@user)
    end
  end

  context "Template set_ownership action" do
    let(:template) { FactoryBot.create(:template_vmware, :name => "template") }

    it "to an invalid template" do
      api_basic_authorize action_identifier(:templates, :set_ownership)

      post(api_template_url(nil, 999_999), :params => gen_request(:set_ownership, "owner" => {"id" => 1}))

      expect(response).to have_http_status(:not_found)
    end

    it "without appropriate action role" do
      api_basic_authorize

      post(api_template_url(nil, template), :params => gen_request(:set_ownership, "owner" => {"id" => 1}))

      expect(response).to have_http_status(:forbidden)
    end

    it "with missing owner or group" do
      api_basic_authorize action_identifier(:templates, :set_ownership)

      post(api_template_url(nil, template), :params => gen_request(:set_ownership))

      expect_bad_request("Must specify an owner or group")
    end

    it "with invalid owner" do
      api_basic_authorize action_identifier(:templates, :set_ownership)

      post(api_template_url(nil, template), :params => gen_request(:set_ownership, "owner" => {"id" => 999_999}))

      expect_single_action_result(:success => false, :message => /.*/, :href => api_template_url(nil, template))
    end

    it "to a template" do
      api_basic_authorize action_identifier(:templates, :set_ownership)

      post(api_template_url(nil, template), :params => gen_request(:set_ownership, "owner" => {"userid" => @user.userid}))

      expect_set_ownership_success(template, api_template_url(nil, template), @user)
    end

    it "by owner name to a template" do
      api_basic_authorize action_identifier(:templates, :set_ownership)

      post(api_template_url(nil, template), :params => gen_request(:set_ownership, "owner" => {"name" => @user.name}))

      expect_set_ownership_success(template, api_template_url(nil, template), @user)
    end

    it "by owner href to a template" do
      api_basic_authorize action_identifier(:templates, :set_ownership)

      post(api_template_url(nil, template), :params => gen_request(:set_ownership, "owner" => {"href" => api_user_url(nil, @user)}))

      expect_set_ownership_success(template, api_template_url(nil, template), @user)
    end

    it "by owner id to a template" do
      api_basic_authorize action_identifier(:templates, :set_ownership)

      post(api_template_url(nil, template), :params => gen_request(:set_ownership, "owner" => {"id" => @user.id}))

      expect_set_ownership_success(template, api_template_url(nil, template), @user)
    end

    it "by group id to a template" do
      api_basic_authorize action_identifier(:templates, :set_ownership)

      post(api_template_url(nil, template), :params => gen_request(:set_ownership, "group" => {"id" => @group.id}))

      expect_set_ownership_success(template, api_template_url(nil, template), nil, @group)
    end

    it "by group description to a template" do
      api_basic_authorize action_identifier(:templates, :set_ownership)

      post(api_template_url(nil, template),
           :params => gen_request(:set_ownership, "group" => {"description" => @group.description}))

      expect_set_ownership_success(template, api_template_url(nil, template), nil, @group)
    end

    it "with owner and group to a template" do
      api_basic_authorize action_identifier(:templates, :set_ownership)

      post(api_template_url(nil, template), :params => gen_request(:set_ownership, "owner" => {"userid" => @user.userid}))

      expect_set_ownership_success(template, api_template_url(nil, template), @user)
    end

    it "to multiple templates" do
      api_basic_authorize action_identifier(:templates, :set_ownership)

      template1 = FactoryBot.create(:template_vmware, :name => "template1")
      template2 = FactoryBot.create(:template_vmware, :name => "template2")

      template_urls = [api_template_url(nil, template1), api_template_url(nil, template2)]
      post(api_templates_url, :params => gen_request(:set_ownership, {"owner" => {"userid" => @user.userid}}, *template_urls))

      expect_multiple_action_result(2)
      expect_result_resources_to_include_hrefs("results", [api_template_url(nil, template1), api_template_url(nil, template2)])
      expect(template1.reload.evm_owner).to eq(@user)
      expect(template2.reload.evm_owner).to eq(@user)
    end
  end
end
