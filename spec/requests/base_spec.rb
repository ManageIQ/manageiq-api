describe "Base Controller API" do
  include Spec::Support::SupportsHelper

  let(:vm)  { FactoryBot.create(:vm_vmware) }
  let(:vm2) { FactoryBot.create(:vm_amazon) }

  it "lists all of the vms" do
    api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)

    vm
    vm2
    get api_vms_url

    expect_query_result(:vms, 2, 2)
  end

  it "lists specific vms (matching type)" do
    api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)

    vm
    vm2
    get api_vms_url, :params => {:type => vm.type}

    expect_query_result(:vms, 1, 1)
  end

  it "lists specific vms (parent type)" do
    api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)

    vm
    vm2
    type = FactoryBot.build(:vm_cloud).type
    get api_vms_url, :params => {:type => type}

    expect_query_result(:vms, 1, 1)
  end
end
