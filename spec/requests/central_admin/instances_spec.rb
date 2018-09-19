describe "/api/instances central admin" do
  let(:api_connection)           { double("ApiClient", :instances => api_instances_collection) }
  let(:api_instance)             { double("Instance") }
  let(:api_instances_collection) { double("/api/instances") }
  let(:region_remote)            { FactoryGirl.create(:miq_region) }
  let!(:vm_remote)               { FactoryGirl.create(:vm_amazon, :id => ApplicationRecord.id_in_region(1, region_remote.region)) }

  shared_examples "basic operations" do |operation|
    let(:operation) { operation }
    it operation.to_s do
      api_basic_authorize(action_identifier(:instances, operation))

      expect(InterRegionApiMethodRelay).to receive(:api_client_connection_for_region).with(region_remote.region).and_return(api_connection)
      expect(api_instances_collection).to receive(:find).with(vm_remote.id).and_return(api_instance)
      expect(api_instance).to receive(operation)

      post(api_instance_url(nil, vm_remote), :params => gen_request(operation))
    end
  end

  include_examples "basic operations", :pause
  include_examples "basic operations", :reboot_guest
  include_examples "basic operations", :reset
  include_examples "basic operations", :shelve
  include_examples "basic operations", :start
  include_examples "basic operations", :stop
  include_examples "basic operations", :suspend
  include_examples "basic operations", :terminate
end
