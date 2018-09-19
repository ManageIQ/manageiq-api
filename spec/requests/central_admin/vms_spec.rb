describe "/api/vms central admin" do
  let(:api_connection)     { double("ApiClient", :vms => api_vms_collection) }
  let(:api_vm)             { double("Vm") }
  let(:api_vms_collection) { double("/api/vms") }
  let(:region_remote)      { FactoryGirl.create(:miq_region) }
  let!(:vm_remote)         { FactoryGirl.create(:vm_vmware, :id => ApplicationRecord.id_in_region(1, region_remote.region)) }

  shared_examples "basic operations" do |operation|
    let(:operation) { operation }
    it operation.to_s do
      api_basic_authorize(action_identifier(:vms, operation))

      expect(InterRegionApiMethodRelay).to receive(:api_client_connection_for_region).with(region_remote.region).and_return(api_connection)
      expect(api_vms_collection).to receive(:find).with(vm_remote.id).and_return(api_vm)
      expect(api_vm).to receive(operation)

      post(api_vm_url(nil, vm_remote), :params => gen_request(operation))
    end
  end

  include_examples "basic operations", :pause
  include_examples "basic operations", :reboot_guest
  include_examples "basic operations", :refresh
  include_examples "basic operations", :reset
  include_examples "basic operations", :scan
  include_examples "basic operations", :shelve
  include_examples "basic operations", :shelve_offload
  include_examples "basic operations", :shutdown_guest
  include_examples "basic operations", :start
  include_examples "basic operations", :stop
  include_examples "basic operations", :suspend
end
