RSpec.describe "Instances API" do
  def update_raw_power_state(state, *instances)
    instances.each { |instance| instance.update_attributes!(:raw_power_state => state) }
  end

  let(:zone) { FactoryGirl.create(:zone, :name => "api_zone") }
  let(:ems) { FactoryGirl.create(:ems_openstack_infra, :zone => zone) }
  let(:host) { FactoryGirl.create(:host_openstack_infra) }
  let(:instance) { FactoryGirl.create(:vm_openstack, :ems_id => ems.id, :host => host) }
  let(:instance1) { FactoryGirl.create(:vm_openstack, :ems_id => ems.id, :host => host) }
  let(:instance2) { FactoryGirl.create(:vm_openstack, :ems_id => ems.id, :host => host) }
  let(:instance_url) { api_instance_url(nil, instance) }
  let(:instance1_url) { api_instance_url(nil, instance1) }
  let(:instance2_url) { api_instance_url(nil, instance2) }
  let(:invalid_instance_url) { api_instance_url(nil, 999_999) }
  let(:instances_list) { [instance1_url, instance2_url] }

  context "Instance index" do
    it "lists only the cloud instances (no infrastructure vms)" do
      api_basic_authorize collection_action_identifier(:instances, :read, :get)
      instance = FactoryGirl.create(:vm_openstack)
      _vm = FactoryGirl.create(:vm_vmware)

      get(api_instances_url)

      expect_query_result(:instances, 1, 1)
      expect_result_resources_to_include_hrefs("resources", [api_instance_url(nil, instance)])
    end
  end

  describe "instance terminate action" do
    it "responds not found for an invalid instance" do
      api_basic_authorize action_identifier(:instances, :terminate)

      post(invalid_instance_url, :params => gen_request(:terminate))

      expect(response).to have_http_status(:not_found)
    end

    it "responds forbidden for an invalid instance without appropriate role" do
      api_basic_authorize

      post(invalid_instance_url, :params => gen_request(:terminate))

      expect(response).to have_http_status(:forbidden)
    end

    it "terminates a single valid Instance" do
      api_basic_authorize action_identifier(:instances, :terminate)

      post(instance_url, :params => gen_request(:terminate))

      expect_single_action_result(
        :success => true,
        :message => /#{instance.id}.* terminating/i,
        :href    => api_instance_url(nil, instance)
      )
    end

    it "terminates multiple valid Instances" do
      api_basic_authorize collection_action_identifier(:instances, :terminate)

      post(api_instances_url, :params => gen_request(:terminate, [{"href" => instance1_url}, {"href" => instance2_url}]))

      expected = {
        "results" => a_collection_containing_exactly(
          a_hash_including(
            "message" => a_string_matching(/#{instance1.id}.* terminating/i),
            "success" => true,
            "href"    => api_instance_url(nil, instance1)
          ),
          a_hash_including(
            "message" => a_string_matching(/#{instance2.id}.* terminating/i),
            "success" => true,
            "href"    => api_instance_url(nil, instance2)
          )
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "instance stop action" do
    it "responds not found for an invalid instance" do
      api_basic_authorize action_identifier(:instances, :stop)

      post(invalid_instance_url, :params => gen_request(:stop))

      expect(response).to have_http_status(:not_found)
    end

    it "stopping an invalid instance without appropriate role is forbidden" do
      api_basic_authorize

      post(invalid_instance_url, :params => gen_request(:stop))

      expect(response).to have_http_status(:forbidden)
    end

    it "fails to stop a powered off instance" do
      api_basic_authorize action_identifier(:instances, :stop)
      update_raw_power_state("poweredOff", instance)

      post(instance_url, :params => gen_request(:stop))

      expect_single_action_result(:success => false, :message => "is not powered on", :href => api_instance_url(nil, instance))
    end

    it "stops a valid instance" do
      api_basic_authorize action_identifier(:instances, :stop)

      post(instance_url, :params => gen_request(:stop))

      expect_single_action_result(:success => true, :message => "stopping", :href => api_instance_url(nil, instance), :task => true)
    end

    it "stops multiple valid instances" do
      api_basic_authorize action_identifier(:instances, :stop)

      post(api_instances_url, :params => gen_request(:stop, nil, instance1_url, instance2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_instance_url(nil, instance1), api_instance_url(nil, instance2)])
    end
  end

  describe "instance start action" do
    it "responds not found for an invalid instance" do
      api_basic_authorize action_identifier(:instances, :start)

      post(invalid_instance_url, :params => gen_request(:start))

      expect(response).to have_http_status(:not_found)
    end

    it "starting an invalid instance without appropriate role is forbidden" do
      api_basic_authorize

      post(invalid_instance_url, :params => gen_request(:start))

      expect(response).to have_http_status(:forbidden)
    end

    it "fails to start a powered on instance" do
      api_basic_authorize action_identifier(:instances, :start)

      post(instance_url, :params => gen_request(:start))

      expect_single_action_result(:success => false, :message => "is powered on", :href => api_instance_url(nil, instance))
    end

    it "starts an instance" do
      api_basic_authorize action_identifier(:instances, :start)
      update_raw_power_state("poweredOff", instance)

      post(instance_url, :params => gen_request(:start))

      expect_single_action_result(:success => true, :message => "starting", :href => api_instance_url(nil, instance), :task => true)
    end

    it "starts multiple instances" do
      api_basic_authorize action_identifier(:instances, :start)
      update_raw_power_state("poweredOff", instance1, instance2)

      post(api_instances_url, :params => gen_request(:start, nil, instance1_url, instance2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_instance_url(nil, instance1), api_instance_url(nil, instance2)])
    end
  end

  describe "instance pause action" do
    it "responds not found for an invalid instance" do
      api_basic_authorize action_identifier(:instances, :pause)

      post(invalid_instance_url, :params => gen_request(:pause))

      expect(response).to have_http_status(:not_found)
    end

    it "pausing an invalid instance without appropriate role is forbidden" do
      api_basic_authorize

      post(invalid_instance_url, :params => gen_request(:pause))

      expect(response).to have_http_status(:forbidden)
    end

    it "fails to pause a powered off instance" do
      api_basic_authorize action_identifier(:instances, :pause)
      update_raw_power_state("poweredOff", instance)

      post(instance_url, :params => gen_request(:pause))

      expect_single_action_result(:success => false, :message => "is not powered on", :href => api_instance_url(nil, instance))
    end

    it "fails to pause a paused instance" do
      api_basic_authorize action_identifier(:instances, :pause)
      update_raw_power_state("paused", instance)

      post(instance_url, :params => gen_request(:pause))

      expect_single_action_result(:success => false, :message => "is not powered on", :href => api_instance_url(nil, instance))
    end

    it "pauses an instance" do
      api_basic_authorize action_identifier(:instances, :pause)

      post(instance_url, :params => gen_request(:pause))

      expect_single_action_result(:success => true, :message => "pausing", :href => api_instance_url(nil, instance), :task => true)
    end

    it "pauses multiple instances" do
      api_basic_authorize action_identifier(:instances, :pause)

      post(api_instances_url, :params => gen_request(:pause, nil, instance1_url, instance2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_instance_url(nil, instance1), api_instance_url(nil, instance2)])
    end
  end

  context "Instance suspend action" do
    it "responds not found for an invalid instance" do
      api_basic_authorize action_identifier(:instances, :suspend)

      post(invalid_instance_url, :params => gen_request(:suspend))

      expect(response).to have_http_status(:not_found)
    end

    it "responds forbidden for an invalid instance without appropriate role" do
      api_basic_authorize

      post(invalid_instance_url, :params => gen_request(:suspend))

      expect(response).to have_http_status(:forbidden)
    end

    it "cannot suspend a powered off instance" do
      api_basic_authorize action_identifier(:instances, :suspend)
      update_raw_power_state("poweredOff", instance)

      post(instance_url, :params => gen_request(:suspend))

      expect_single_action_result(:success => false, :message => "is not powered on", :href => api_instance_url(nil, instance))
    end

    it "cannot suspend a suspended instance" do
      api_basic_authorize action_identifier(:instances, :suspend)
      update_raw_power_state("suspended", instance)

      post(instance_url, :params => gen_request(:suspend))

      expect_single_action_result(:success => false, :message => "is not powered on", :href => api_instance_url(nil, instance))
    end

    it "suspends an instance" do
      api_basic_authorize action_identifier(:instances, :suspend)

      post(instance_url, :params => gen_request(:suspend))

      expect_single_action_result(:success => true, :message => "suspending", :href => api_instance_url(nil, instance), :task => true)
    end

    it "suspends multiple instances" do
      api_basic_authorize action_identifier(:instances, :suspend)

      post(api_instances_url, :params => gen_request(:suspend, nil, instance1_url, instance2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_instance_url(nil, instance1), api_instance_url(nil, instance2)])
    end
  end

  context "Instance shelve action" do
    it "responds not found for an invalid instance" do
      api_basic_authorize action_identifier(:instances, :shelve)

      post(invalid_instance_url, :params => gen_request(:shelve))

      expect(response).to have_http_status(:not_found)
    end

    it "responds forbidden for an invalid instance without appropriate role" do
      api_basic_authorize

      post(invalid_instance_url, :params => gen_request(:shelve))

      expect(response).to have_http_status(:forbidden)
    end

    it "shelves a powered off instance" do
      api_basic_authorize action_identifier(:instances, :shelve)
      update_raw_power_state("SHUTOFF", instance)

      post(instance_url, :params => gen_request(:shelve))

      expect_single_action_result(:success => true, :message => 'shelving', :href => api_instance_url(nil, instance))
    end

    it "shelves a suspended instance" do
      api_basic_authorize action_identifier(:instances, :shelve)
      update_raw_power_state("SUSPENDED", instance)

      post(instance_url, :params => gen_request(:shelve))

      expect_single_action_result(:success => true, :message => 'shelving', :href => api_instance_url(nil, instance))
    end

    it "shelves a paused instance" do
      api_basic_authorize action_identifier(:instances, :shelve)
      update_raw_power_state("PAUSED", instance)

      post(instance_url, :params => gen_request(:shelve))

      expect_single_action_result(:success => true, :message => 'shelving', :href => api_instance_url(nil, instance))
    end

    it "cannot shelve a shelved instance" do
      api_basic_authorize action_identifier(:instances, :shelve)
      update_raw_power_state("SHELVED", instance)

      post(instance_url, :params => gen_request(:shelve))

      expect_single_action_result(
        :success => false,
        :message => "The VM can't be shelved, current state has to be powered on, off, suspended or paused",
        :href    => api_instance_url(nil, instance)
      )
    end

    it "shelves an instance" do
      api_basic_authorize action_identifier(:instances, :shelve)

      post(instance_url, :params => gen_request(:shelve))

      expect_single_action_result(:success => true,
                                  :message => "shelving",
                                  :href    => api_instance_url(nil, instance),
                                  :task    => true)
    end

    it "shelves multiple instances" do
      api_basic_authorize action_identifier(:instances, :shelve)

      post(api_instances_url, :params => gen_request(:shelve, nil, instance1_url, instance2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_instance_url(nil, instance1), api_instance_url(nil, instance2)])
    end
  end

  describe "instance reboot guest action" do
    it "responds not found for an invalid instance" do
      api_basic_authorize action_identifier(:instances, :reboot_guest)

      post(invalid_instance_url, :params => gen_request(:reboot_guest))

      expect(response).to have_http_status(:not_found)
    end

    it "responds forbidden for an invalid instance without appropriate role" do
      api_basic_authorize

      post(invalid_instance_url, :params => gen_request(:reboot_guest))

      expect(response).to have_http_status(:forbidden)
    end

    it "fails to reboot a powered off instance" do
      api_basic_authorize action_identifier(:instances, :reboot_guest)
      update_raw_power_state("poweredOff", instance)

      post(instance_url, :params => gen_request(:reboot_guest))

      expect_single_action_result(:success => false, :message => "is not powered on", :href => api_instance_url(nil, instance))
    end

    it "reboots a valid instance" do
      api_basic_authorize action_identifier(:instances, :reboot_guest)

      post(instance_url, :params => gen_request(:reboot_guest))

      expect_single_action_result(:success => true, :message => "rebooting", :href => api_instance_url(nil, instance), :task => true)
    end

    it "reboots multiple valid instances" do
      api_basic_authorize action_identifier(:instances, :reboot_guest)

      post(api_instances_url, :params => gen_request(:reboot_guest, nil, instance1_url, instance2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_instance_url(nil, instance1), api_instance_url(nil, instance2)])
    end
  end

  describe "instance reset action" do
    it "responds not found for an invalid instance" do
      api_basic_authorize action_identifier(:instances, :reset)

      post(invalid_instance_url, :params => gen_request(:reset))

      expect(response).to have_http_status(:not_found)
    end

    it "responds forbidden for an invalid instance without appropriate role" do
      api_basic_authorize

      post(invalid_instance_url, :params => gen_request(:reset))

      expect(response).to have_http_status(:forbidden)
    end

    it "fails to reset a powered off instance" do
      api_basic_authorize action_identifier(:instances, :reset)
      update_raw_power_state("poweredOff", instance)

      post(instance_url, :params => gen_request(:reset))

      expect_single_action_result(:success => false, :message => "is not powered on", :href => api_instance_url(nil, instance))
    end

    it "resets a valid instance" do
      api_basic_authorize action_identifier(:instances, :reset)

      post(instance_url, :params => gen_request(:reset))

      expect_single_action_result(:success => true, :message => "resetting", :href => api_instance_url(nil, instance), :task => true)
    end

    it "resets multiple valid instances" do
      api_basic_authorize action_identifier(:instances, :reset)

      post(api_instances_url, :params => gen_request(:reset, nil, instance1_url, instance2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_instance_url(nil, instance1), api_instance_url(nil, instance2)])
    end
  end

  context 'load balancers subcollection' do
    before do
      @vm = FactoryGirl.create(:vm_amazon)
      @load_balancer = FactoryGirl.create(:load_balancer_amazon)
      load_balancer_listener = FactoryGirl.create(:load_balancer_listener_amazon)
      load_balancer_pool = FactoryGirl.create(:load_balancer_pool_amazon)
      load_balancer_pool_member = FactoryGirl.create(:load_balancer_pool_member_amazon)
      @load_balancer.load_balancer_listeners << load_balancer_listener
      load_balancer_listener.load_balancer_pools << load_balancer_pool
      load_balancer_pool.load_balancer_pool_members << load_balancer_pool_member
      @vm.load_balancer_pool_members << load_balancer_pool_member
    end

    it 'queries all load balancers on an instance' do
      api_basic_authorize subcollection_action_identifier(:instances, :load_balancers, :read, :get)
      expected = {
        'name'      => 'load_balancers',
        'resources' => [
          { 'href' => api_instance_load_balancer_url(nil, @vm, @load_balancer) }
        ]
      }
      get(api_instance_load_balancers_url(nil, @vm))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "will not show an instance's load balancers without the appropriate role" do
      api_basic_authorize

      get(api_instance_load_balancers_url(nil, @vm))

      expect(response).to have_http_status(:forbidden)
    end

    it 'queries a single load balancer on an instance' do
      api_basic_authorize subcollection_action_identifier(:instances, :load_balancers, :read, :get)
      get(api_instance_load_balancer_url(nil, @vm, @load_balancer))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => @load_balancer.id.to_s)
    end

    it "will not show an instance's load balancer without the appropriate role" do
      api_basic_authorize

      get(api_instance_load_balancer_url(nil, @vm, @load_balancer))

      expect(response).to have_http_status(:forbidden)
    end
  end
end
