#
# REST API Request Tests - /api/vms
#
describe "Vms API" do
  include Spec::Support::SupportsHelper

  let(:zone)       { FactoryBot.create(:zone, :name => "api_zone") }
  let(:ems)        { FactoryBot.create(:ems_vmware, :zone => zone) }
  let(:host)       { FactoryBot.create(:host) }

  let(:vm)                 { FactoryBot.create(:vm_vmware,    :host => host, :ems_id => ems.id, :raw_power_state => "poweredOn") }
  let(:vm_openstack)       { FactoryBot.create(:vm_openstack, :host => host, :ems_id => ems.id, :raw_power_state => "ACTIVE") }
  let(:vm_openstack1)      { FactoryBot.create(:vm_openstack, :host => host, :ems_id => ems.id, :raw_power_state => "ACTIVE") }
  let(:vm_openstack2)      { FactoryBot.create(:vm_openstack, :host => host, :ems_id => ems.id, :raw_power_state => "ACTIVE") }
  let(:vm_openstack_url)   { api_vm_url(nil, vm_openstack) }
  let(:vm_openstack1_url)  { api_vm_url(nil, vm_openstack1) }
  let(:vm_openstack2_url)  { api_vm_url(nil, vm_openstack2) }
  let(:vms_openstack_list) { [vm_openstack1_url, vm_openstack2_url] }
  let(:vm1)                { FactoryBot.create(:vm_vmware,    :host => host, :ems_id => ems.id, :raw_power_state => "poweredOn") }
  let(:vm2)                { FactoryBot.create(:vm_vmware,    :host => host, :ems_id => ems.id, :raw_power_state => "poweredOn") }
  let(:vm1_url)            { api_vm_url(nil, vm1) }
  let(:vm2_url)            { api_vm_url(nil, vm2) }
  let(:vms_list)           { [vm1_url, vm2_url] }
  let(:vm_guid)            { vm.guid }
  let(:vm_url)             { api_vm_url(nil, vm) }

  let(:invalid_vm_url) { api_vm_url(nil, ApplicationRecord.id_in_region(999_999, ApplicationRecord.my_region_number)) }

  def update_raw_power_state(state, *vms)
    vms.each { |vm| vm.update!(:raw_power_state => state) }
  end

  def add_hardware_and_os_to_vms
    [vm, vm1, vm2, vm_openstack, vm_openstack1, vm_openstack2].each do |vm_record|
      cs = ComputerSystem.create
      OperatingSystem.create(:name => "linux", :vm_or_template => vm_record, :computer_system => cs)
      FactoryBot.create(:hardware, :vm_or_template => vm_record, :host => host)
    end
  end

  def query_match_regexp(*tables)
    /SELECT.*FROM\s"(?:#{tables.flatten.join("|")})"/m
  end

  context 'href_slug' do
    it 'returns the correct value for cloud instances' do
      vm_cloud = FactoryBot.create(:vm_amazon)
      api_basic_authorize(action_identifier(:vms, :read, :resource_actions, :get))

      get(api_vm_url(nil, vm_cloud), :params => { :attributes => 'href_slug'})

      expect(response.parsed_body['href_slug']).to eq("vms/#{vm_cloud.id}")
    end
  end

  context 'Vm index' do
    before do
      # Will not be included in the result (base model is Vm)
      FactoryBot.create(:template)
      FactoryBot.create(:template)

      # Preload records
      _vms = [vm, vm1, vm2, vm_openstack, vm_openstack1, vm_openstack2]

      # Only once for the main query
      expect(Rbac).to receive(:filtered).exactly(2).times.and_call_original
      expect(Rbac).to receive(:filtered_object).never
    end

    it "lists all of the vms" do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
      get api_vms_url, :params => {:expand => "resources", :attributes => "num_cpu,name"}

      expect(response.parsed_body["subcount"]).to eq 6
    end

    it "properly filters with Rbac" do
      # Add tenant permissions
      tenant = FactoryBot.create(:tenant)
      role   = FactoryBot.create(:miq_user_role)
      group  = FactoryBot.create(:miq_group, :tenant => tenant, :miq_user_role => role)

      # Update user permissions
      @user.update(:miq_groups => [group])
      @role = role

      # Assign vms to a particular group
      vm_openstack1.update(:miq_group => group)
      vm_openstack2.update(:miq_group => group)

      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
      get api_vms_url, :params => {:expand => "resources", :attributes => "num_cpu,name,vendor"}

      expect(response.parsed_body["subcount"]).to eq 2
      expect_results_to_match_hash("resources",
                                   [{"vendor" => "openstack"},
                                    {"vendor" => "openstack"}])
    end

    context "with nested indirect virtual attribute ('operating_system.computer_system.created_at')" do
      before { add_hardware_and_os_to_vms }

      it "removes N+1's from the index query for subcollections/virtual_attributes" do
        api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
        query_match = query_match_regexp("vms", "operating_systems", "computer_systems")

        expect {
          get api_vms_url, :params => {
            :expand     => "resources",
            :attributes => "operating_system.computer_system.created_at,name"
          }
        }.to make_database_queries(:count => 3, :matching => query_match)

        expected = {
          "resources" => a_collection_including(
            a_hash_including(
              "name"             => vm.name,
              "operating_system" => {
                "computer_system" => {
                  "created_at" => vm.operating_system.computer_system.created_at.to_formatted_s(:iso8601)
                }
              }
            ),
            a_hash_including(
              "name"             => vm1.name,
              "operating_system" => {
                "computer_system" => {
                  "created_at" => vm1.operating_system.computer_system.created_at.to_formatted_s(:iso8601)
                }
              }
            )
          )
        }

        expect(response.parsed_body).to include(expected)
      end
    end

    context "with direct virtual column with :uses => Array ('os_image_name')" do
      before { add_hardware_and_os_to_vms }

      it "removes N+1's from the index query for subcollections/virtual_attributes" do
        api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
        query_match = query_match_regexp("vms", "hardwares", "operating_systems")

        expect {
          get api_vms_url, :params => {
            :expand     => "resources",
            :attributes => "os_image_name,name"
          }
        }.to make_database_queries(:count => 3, :matching => query_match)

        expected = {
          "resources" => a_collection_including(
            a_hash_including("name" => vm.name, "os_image_name" => vm.os_image_name),
            a_hash_including("name" => vm1.name, "os_image_name" => vm1.os_image_name)
          )
        }

        expect(response.parsed_body).to include(expected)
      end
    end

    context "with direct virtual column with :uses => String/Symbol ('v_owning_cluster')" do
      let!(:vm3) { FactoryBot.create(:vm_vmware, :ems_id => ems.id, :ems_cluster => FactoryBot.create(:ems_cluster)) }

      it "removes N+1's from the index query for subcollections/virtual_attributes" do
        api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
        query_match = query_match_regexp("vms", "ems_clusters")

        expect {
          get api_vms_url, :params => {
            :expand     => "resources",
            :attributes => "v_owning_cluster,name"
          }
        }.to make_database_queries(:count => 3, :matching => query_match)

        expected = {
          "resources" => a_collection_including(
            a_hash_including("name" => vm.name, "v_owning_cluster" => vm.v_owning_cluster),
            a_hash_including("name" => vm1.name, "v_owning_cluster" => vm1.v_owning_cluster)
          )
        }

        expect(response.parsed_body).to include(expected)
      end
    end

    context "with direct virtual column with :uses => Hash ('has_rdm_disk')" do
      before do
        vm3      = FactoryBot.create(:vm_vmware, :name => "myvmware", :ems_id => ems.id)
        hardware = FactoryBot.create(:hardware, :vm_or_template => vm3, :host => host)
        Disk.create(:hardware => hardware)
        Disk.create(:hardware => hardware, :disk_type => "rdm")
      end

      it "removes N+1's from the index query for subcollections/virtual_attributes" do
        api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
        query_match = query_match_regexp("vms", "hardwares", "disks")

        expect {
          get api_vms_url, :params => {
            :expand     => "resources",
            :attributes => "has_rdm_disk,name"
          }
          # ActiveRecord does a few extra queries when doing this relation + includes
        }.to make_database_queries(:count => 5, :matching => query_match)

        expected = {
          "resources" => a_collection_including(
            a_hash_including("name" => vm.name, "has_rdm_disk" => vm.has_rdm_disk),
            a_hash_including("name" => vm1.name, "has_rdm_disk" => vm1.has_rdm_disk)
          )
        }

        expect(response.parsed_body).to include(expected)
      end
    end

    context "with multiple direct virtual columns" do
      before do
        add_hardware_and_os_to_vms

        vm3      = FactoryBot.create(:vm_vmware, :name => "myvmware", :ems_id => ems.id)
        hardware = FactoryBot.create(:hardware, :vm_or_template => vm3, :host => host)
        Disk.create(:hardware => hardware)
        Disk.create(:hardware => hardware, :disk_type => "rdm")
      end

      it "removes N+1's from the index query for subcollections/virtual_attributes" do
        api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
        query_match = query_match_regexp("vms", "operating_systems", "computer_systems", "hardwares", "disks")

        expect {
          get api_vms_url, :params => {
            :expand     => "resources",
            :attributes => "os_image_name,has_rdm_disk,lans,name"
          }
        }.to make_database_queries(:count => 5, :matching => query_match)

        expected = {
          "resources" => a_collection_including(
            a_hash_including("name" => vm.name, "os_image_name" => vm.os_image_name, "has_rdm_disk" => vm.has_rdm_disk, "lans" => vm.lans),
            a_hash_including("name" => vm1.name, "os_image_name" => vm1.os_image_name, "has_rdm_disk" => vm1.has_rdm_disk, "lans" => vm1.lans)
          )
        }

        expect(response.parsed_body).to include(expected)
      end
    end

    context "with indirect virtual attribute ('hardware.cpu_sockets')" do
      before { add_hardware_and_os_to_vms }

      it "removes N+1's from the index query for subcollections/virtual_attributes" do
        api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
        query_match = query_match_regexp("vms", "hardwares")

        expect {
          get api_vms_url, :params => {
            :expand     => "resources",
            :attributes => "hardware.cpu_sockets,name"
          }
        }.to make_database_queries(:count => 3, :matching => query_match)

        expected = {
          "resources" => a_collection_including(
            a_hash_including("name" => vm.name, "hardware" => {"cpu_sockets" => vm.hardware.cpu_sockets}),
            a_hash_including("name" => vm1.name, "hardware" => {"cpu_sockets" => vm1.hardware.cpu_sockets})
          )
        }

        expect(response.parsed_body).to include(expected)
      end
    end

    context "with direct virtual attribute ('num_cpus')" do
      before { add_hardware_and_os_to_vms }

      it "removes N+1's from the index query for subcollections/virtual_attributes" do
        api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
        query_match = query_match_regexp("vms", "hardwares")

        expect {
          get api_vms_url, :params => {
            :expand     => "resources",
            :attributes => "num_cpu,name"
          }
        }.to make_database_queries(:count => 3, :matching => query_match)

        expected = {
          "resources" => a_collection_including(
            a_hash_including("name" => vm.name, "num_cpu" => vm.num_cpu),
            a_hash_including("name" => vm1.name, "num_cpu" => vm1.num_cpu)
          )
        }

        expect(response.parsed_body).to include(expected)
      end
    end
  end

  context "Vm index with nested indirect virtual attribute that participates in Rbac ('hardware.host.name')" do
    # Can't have `expect(Rbac).to receive(:filtered_object).never` in this block
    before do
      # Preload records
      _vms = [vm, vm1, vm2, vm_openstack, vm_openstack1, vm_openstack2]

      add_hardware_and_os_to_vms

      host.update(:ext_management_system => ems)
    end

    it "removes N+1's from the index query for subcollections/virtual_attributes" do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
      query_match = query_match_regexp("vms", "hardwares", "hosts")

      expect {
        get api_vms_url, :params => {
          :expand     => "resources",
          :attributes => "hardware.host.name,name"
        }
      }.to make_database_queries(:count => 21, :matching => query_match)

      expected = {
        "resources" => a_collection_including(
          a_hash_including(
            "name"     => vm.name,
            "hardware" => {
              "host" => {
                "name" => vm.hardware.host.name
              }
            }
          ),
          a_hash_including(
            "name"     => vm1.name,
            "hardware" => {
              "host" => {
                "name" => vm1.hardware.host.name
              }
            }
          )
        )
      }

      expect(response.parsed_body).to include(expected)
    end
  end

  context 'Vm edit' do
    let(:new_vms) { FactoryBot.create_list(:vm_openstack, 2) }

    before do
      vm.set_child(vm_openstack)
      vm.set_parent(vm_openstack1)
    end

    it 'cannot edit a VM without an appropriate role' do
      api_basic_authorize

      post(api_vm_url(nil, vm), :params => { :action => 'edit' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can edit a VM with an appropriate role' do
      api_basic_authorize collection_action_identifier(:vms, :edit)
      children = new_vms.collect do |vm|
        { 'href' => api_vm_url(nil, vm) }
      end

      post(
        api_vm_url(nil, vm),
        :params => {
          :action          => 'edit',
          :description     => 'bar',
          :name            => 'drew was here',
          :child_resources => children,
          :custom_1        => 'foobar',
          :custom_9        => 'fizzbuzz',
          :parent_resource => { :href => api_vm_url(nil, vm_openstack2) }
        }
      )

      expected = {
        'description' => 'bar'
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
      expect(vm.reload.children).to match_array(new_vms)
      expect(vm.parent).to eq(vm_openstack2)
      expect(vm.name).to eq('drew was here')
      expect(vm.custom_1).to eq('foobar')
      expect(vm.custom_9).to eq('fizzbuzz')
    end

    it 'only allows edit of custom_1, description, name, parent, and children' do
      api_basic_authorize collection_action_identifier(:vms, :edit)

      post(api_vm_url(nil, vm), :params => { :action => 'edit', :name => 'foo', :autostart => true, :power_state => 'off' })

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => 'Cannot edit VM - Cannot edit values autostart, power_state'
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'can edit multiple vms' do
      api_basic_authorize collection_action_identifier(:vms, :edit)

      post(api_vms_url, :params => { :action => 'edit', :resources => [{ :id => vm.id, :description => 'foo' }, { :id => vm_openstack.id, :description => 'bar'}] })

      expected = {
        'results' => [
          a_hash_including('description' => 'foo'),
          a_hash_including('description' => 'bar')
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires a valid child/parent relationship ' do
      api_basic_authorize collection_action_identifier(:vms, :edit)

      post(api_vm_url(nil, vm), :params => { :action => 'edit', :parent_resource => { :href => api_user_url(nil, 10) } })

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => 'Cannot edit VM - Invalid relationship type users'
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "Vm accounts subcollection" do
    let(:acct1) { FactoryBot.create(:account, :vm_or_template_id => vm.id, :name => "John") }
    let(:acct2) { FactoryBot.create(:account, :vm_or_template_id => vm.id, :name => "Jane") }
    let(:acct1_url)            { api_vm_account_url(nil, vm, acct1) }
    let(:acct2_url)            { api_vm_account_url(nil, vm, acct2) }

    it "query VM accounts subcollection with no related accounts" do
      api_basic_authorize

      get api_vm_accounts_url(nil, vm)

      expect_empty_query_result(:accounts)
    end

    it "query VM accounts subcollection with two related accounts" do
      api_basic_authorize
      # create resources
      acct1
      acct2

      get api_vm_accounts_url(nil, vm)

      expect_query_result(:accounts, 2)
      expect_result_resources_to_include_hrefs("resources",
                                               [api_vm_account_url(nil, vm, acct1),
                                                api_vm_account_url(nil, vm, acct2)])
    end

    it "query VM accounts subcollection with a valid Account Id" do
      api_basic_authorize

      get acct1_url

      expect_single_resource_query("name" => "John")
    end

    it "query VM accounts subcollection with an invalid Account Id" do
      api_basic_authorize

      get(api_vm_account_url(nil, vm, 999_999))

      expect(response).to have_http_status(:not_found)
    end

    it "query VM accounts subcollection with two related accounts using expand directive" do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
      # create resources
      acct1
      acct2

      get vm_url, :params => { :expand => "accounts" }

      expect_single_resource_query("guid" => vm_guid)
      expect_result_resources_to_include_hrefs("accounts",
                                               [api_vm_account_url(nil, vm, acct1),
                                                api_vm_account_url(nil, vm, acct2)])
    end
  end

  context "Vm software subcollection" do
    let(:sw1) { FactoryBot.create(:guest_application, :vm_or_template_id => vm.id, :name => "Word")  }
    let(:sw2) { FactoryBot.create(:guest_application, :vm_or_template_id => vm.id, :name => "Excel") }
    let(:sw1_url)              { api_vm_software_url(nil, vm, sw1) }
    let(:sw2_url)              { api_vm_software_url(nil, vm, sw2) }

    it "query VM software subcollection with no related software" do
      api_basic_authorize

      get api_vm_softwares_url(nil, vm)

      expect_empty_query_result(:software)
    end

    it "query VM software subcollection with two related software" do
      api_basic_authorize
      # create resources
      sw1
      sw2

      get api_vm_softwares_url(nil, vm)

      expect_query_result(:software, 2)
      expect_result_resources_to_include_hrefs("resources",
                                               [api_vm_software_url(nil, vm, sw1),
                                                api_vm_software_url(nil, vm, sw2)])
    end

    it "query VM software subcollection with a valid Software Id" do
      api_basic_authorize

      get sw1_url

      expect_single_resource_query("name" => "Word")
    end

    it "query VM software subcollection with an invalid Software Id" do
      api_basic_authorize

      get(api_vm_software_url(nil, vm, 999_999))

      expect(response).to have_http_status(:not_found)
    end

    it "query VM software subcollection with two related software using expand directive" do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
      # create resources
      sw1
      sw2

      get api_vm_url(nil, vm), :params => { :expand => "software" }

      expect_single_resource_query("guid" => vm_guid)
      expect_result_resources_to_include_hrefs("software",
                                               [api_vm_software_url(nil, vm, sw1),
                                                api_vm_software_url(nil, vm, sw2)])
    end
  end

  context "Vm start action" do
    it "starts an invalid vm" do
      api_basic_authorize action_identifier(:vms, :start)

      post(invalid_vm_url, :params => gen_request(:start))

      expect(response).to have_http_status(:not_found)
    end

    it "starts an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:start))

      expect(response).to have_http_status(:forbidden)
    end

    it "starts a powered on vm" do
      api_basic_authorize action_identifier(:vms, :start)

      post(vm_url, :params => gen_request(:start))

      expect_bad_request(/is powered on/)
    end

    it "starts a vm" do
      api_basic_authorize action_identifier(:vms, :start)
      update_raw_power_state("poweredOff", vm)

      post(vm_url, :params => gen_request(:start))

      expect_single_action_result(:success => true, :message => /Starting/i, :href => api_vm_url(nil, vm), :task => true)
    end

    it "starting a vm queues it properly" do
      api_basic_authorize action_identifier(:vms, :start)
      update_raw_power_state("poweredOff", vm)

      post(vm_url, :params => gen_request(:start))

      expect_single_action_result(:success => true, :message => /Starting/i, :href => api_vm_url(nil, vm), :task => true)
      expect(MiqQueue.where(:class_name  => vm.class.name,
                            :instance_id => vm.id,
                            :method_name => "start",
                            :zone        => zone.name,
                            :user_id     => @user.id,
                            :group_id    => @user.current_group.id,
                            :tenant_id   => @user.current_tenant.id).count).to eq(1)
    end

    it "starts multiple vms" do
      api_basic_authorize action_identifier(:vms, :start)
      update_raw_power_state("poweredOff", vm1, vm2)

      post(api_vms_url, :params => gen_request(:start, nil, vm1_url, vm2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
    end
  end

  context "Vm stop action" do
    it "stops an invalid vm" do
      api_basic_authorize action_identifier(:vms, :stop)

      post(invalid_vm_url, :params => gen_request(:stop))

      expect(response).to have_http_status(:not_found)
    end

    it "stops an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:stop))

      expect(response).to have_http_status(:forbidden)
    end

    it "stops a powered off vm" do
      api_basic_authorize action_identifier(:vms, :stop)
      update_raw_power_state("poweredOff", vm)

      post(vm_url, :params => gen_request(:stop))

      expect_bad_request(/is not powered on/)
    end

    it "stops a vm" do
      api_basic_authorize action_identifier(:vms, :stop)

      post(vm_url, :params => gen_request(:stop))

      expect_single_action_result(:success => true, :message => /Stopping/i, :href => api_vm_url(nil, vm), :task => true)
      expect(MiqQueue.where(:method_name => "stop",
                            :user_id     => @user.id,
                            :group_id    => @user.current_group.id,
                            :tenant_id   => @user.current_tenant.id).count).to eq(1)
    end

    it "stops multiple vms" do
      api_basic_authorize action_identifier(:vms, :stop)

      post(api_vms_url, :params => gen_request(:stop, nil, vm1_url, vm2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
    end
  end

  context "Vm suspend action" do
    it "suspends an invalid vm" do
      api_basic_authorize action_identifier(:vms, :suspend)

      post(invalid_vm_url, :params => gen_request(:suspend))

      expect(response).to have_http_status(:not_found)
    end

    it "suspends an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:suspend))

      expect(response).to have_http_status(:forbidden)
    end

    it "suspends a powered off vm" do
      api_basic_authorize action_identifier(:vms, :suspend)
      update_raw_power_state("poweredOff", vm)

      post(vm_url, :params => gen_request(:suspend))

      expect_bad_request(/is not powered on/)
    end

    it "suspends a suspended vm" do
      api_basic_authorize action_identifier(:vms, :suspend)
      update_raw_power_state("suspended", vm)

      post(vm_url, :params => gen_request(:suspend))

      expect_bad_request(/is not powered on/)
    end

    it "suspends a vm" do
      api_basic_authorize action_identifier(:vms, :suspend)

      post(vm_url, :params => gen_request(:suspend))

      expect_single_action_result(:success => true, :message => /Suspending/i, :href => api_vm_url(nil, vm), :task => true)
      expect(MiqQueue.where(:method_name => "suspend",
                            :user_id     => @user.id,
                            :group_id    => @user.current_group.id,
                            :tenant_id   => @user.current_tenant.id).count).to eq(1)
    end

    it "suspends multiple vms" do
      api_basic_authorize action_identifier(:vms, :suspend)

      post(api_vms_url, :params => gen_request(:suspend, nil, vm1_url, vm2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
    end
  end

  context "Vm pause action" do
    it "pauses an invalid vm" do
      api_basic_authorize action_identifier(:vms, :pause)

      post(invalid_vm_url, :params => gen_request(:pause))

      expect(response).to have_http_status(:not_found)
    end

    it "pauses an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:pause))

      expect(response).to have_http_status(:forbidden)
    end

    it "pauses a powered off vm" do
      api_basic_authorize action_identifier(:vms, :pause)
      update_raw_power_state("off", vm)

      post(vm_url, :params => gen_request(:pause))

      expect_bad_request(/Feature not available/)
    end

    it "pauses a pauseed vm" do
      api_basic_authorize action_identifier(:vms, :pause)
      update_raw_power_state("paused", vm)

      post(vm_url, :params => gen_request(:pause))

      expect_bad_request(/Feature not available/)
    end

    it "pauses a vm" do
      api_basic_authorize action_identifier(:vms, :pause)

      post(vm_openstack_url, :params => gen_request(:pause))

      expect_single_action_result(:success => true, :message => /Pausing/i, :href => api_vm_url(nil, vm_openstack), :task => true)
      expect(MiqQueue.where(:class_name  => vm_openstack.class.name,
                            :instance_id => vm_openstack.id,
                            :method_name => "pause",
                            :zone        => zone.name,
                            :user_id     => @user.id,
                            :group_id    => @user.current_group.id,
                            :tenant_id   => @user.current_tenant.id).count).to eq(1)
    end

    it "pauses multiple vms" do
      api_basic_authorize action_identifier(:vms, :pause)

      post(api_vms_url, :params => gen_request(:pause, nil, vm_openstack1_url, vm_openstack2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm_openstack1), api_vm_url(nil, vm_openstack2)])
    end
  end

  context "Vm shelve action" do
    it "shelves an invalid vm" do
      api_basic_authorize action_identifier(:vms, :shelve)

      post(invalid_vm_url, :params => gen_request(:shelve))

      expect(response).to have_http_status(:not_found)
    end

    it "shelves an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:shelve))

      expect(response).to have_http_status(:forbidden)
    end

    it "shelves a powered off vm" do
      api_basic_authorize action_identifier(:vms, :shelve)
      update_raw_power_state("SHUTOFF", vm_openstack)

      post(vm_openstack_url, :params => gen_request(:shelve))

      expect_single_action_result(:success => true, :message => /Shelving/i, :href => api_vm_url(nil, vm_openstack))
    end

    it "shelves a suspended vm" do
      api_basic_authorize action_identifier(:vms, :shelve)
      update_raw_power_state("SUSPENDED", vm_openstack)

      post(vm_openstack_url, :params => gen_request(:shelve))

      expect_single_action_result(:success => true, :message => /Shelving/i, :href => api_vm_url(nil, vm_openstack))
    end

    it "shelves a paused off vm" do
      api_basic_authorize action_identifier(:vms, :shelve)
      update_raw_power_state("PAUSED", vm_openstack)

      post(vm_openstack_url, :params => gen_request(:shelve))

      expect_single_action_result(:success => true, :message => /Shelving/i, :href => api_vm_url(nil, vm_openstack))
    end

    it "shelves a shelved vm" do
      api_basic_authorize action_identifier(:vms, :shelve)
      update_raw_power_state("SHELVED", vm_openstack)

      post(vm_openstack_url, :params => gen_request(:shelve))

      expect_bad_request(/current state has to be powered/)
    end

    it "shelves a vm" do
      api_basic_authorize action_identifier(:vms, :shelve)

      post(vm_openstack_url, :params => gen_request(:shelve))

      expect_single_action_result(:success => true, :message => /Shelving/i, :href => api_vm_url(nil, vm_openstack), :task => true)
      expect(MiqQueue.where(:method_name => "shelve",
                            :user_id     => @user.id,
                            :group_id    => @user.current_group.id,
                            :tenant_id   => @user.current_tenant.id).count).to eq(1)
    end

    it "shelve for a VMWare vm is not supported" do
      api_basic_authorize action_identifier(:vms, :shelve)

      post(vm_url, :params => gen_request(:shelve))

      expect_bad_request(/Feature not available/)
    end

    it "shelves multiple vms" do
      api_basic_authorize action_identifier(:vms, :shelve)

      post(api_vms_url, :params => gen_request(:shelve, nil, vm_openstack1_url, vm_openstack2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm_openstack1), api_vm_url(nil, vm_openstack2)])
    end
  end

  context "Vm shelve offload action" do
    it "shelve_offloads an invalid vm" do
      api_basic_authorize action_identifier(:vms, :shelve_offload)

      post(invalid_vm_url, :params => gen_request(:shelve_offload))

      expect(response).to have_http_status(:not_found)
    end

    it "shelve_offloads an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:shelve_offload))

      expect(response).to have_http_status(:forbidden)
    end

    it "shelve_offloads a active vm" do
      api_basic_authorize action_identifier(:vms, :shelve_offload)

      post(vm_openstack_url, :params => gen_request(:shelve_offload))

      expect_bad_request(/current state has to be shelved/)
    end

    it "shelve_offloads a powered off vm" do
      api_basic_authorize action_identifier(:vms, :shelve_offload)
      update_raw_power_state("SHUTOFF", vm_openstack)

      post(vm_openstack_url, :params => gen_request(:shelve_offload))

      expect_bad_request(/current state has to be shelved/)
    end

    it "shelve_offloads a suspended vm" do
      api_basic_authorize action_identifier(:vms, :shelve_offload)
      update_raw_power_state("SUSPENDED", vm_openstack)

      post(vm_openstack_url, :params => gen_request(:shelve_offload))

      expect_bad_request(/current state has to be shelved/)
    end

    it "shelve_offloads a paused off vm" do
      api_basic_authorize action_identifier(:vms, :shelve_offload)
      update_raw_power_state("PAUSED", vm_openstack)

      post(vm_openstack_url, :params => gen_request(:shelve_offload))

      expect_bad_request(/current state has to be shelved/)
    end

    it "shelve_offloads a shelve_offloaded vm" do
      api_basic_authorize action_identifier(:vms, :shelve_offload)
      update_raw_power_state("SHELVED_OFFLOADED", vm_openstack)

      post(vm_openstack_url, :params => gen_request(:shelve_offload))

      expect_bad_request(/current state has to be shelved/)
    end

    it "shelve_offloads a shelved vm" do
      api_basic_authorize action_identifier(:vms, :shelve_offload)
      update_raw_power_state("SHELVED", vm_openstack)

      post(vm_openstack_url, :params => gen_request(:shelve_offload))

      expect_single_action_result(:success => true,
                                  :message => /Shelve-offloading/i,
                                  :href    => api_vm_url(nil, vm_openstack))
      expect(MiqQueue.where(:method_name => "shelve_offload",
                            :user_id     => @user.id,
                            :group_id    => @user.current_group.id,
                            :tenant_id   => @user.current_tenant.id).count).to eq(1)
    end

    it "shelve_offload for a VMWare vm is not supported" do
      api_basic_authorize action_identifier(:vms, :shelve_offload)

      post(vm_url, :params => gen_request(:shelve_offload))

      expect_bad_request(/Feature not available/)
    end

    it "shelve_offloads multiple vms" do
      api_basic_authorize action_identifier(:vms, :shelve_offload)

      update_raw_power_state("SHELVED", vm_openstack1)
      update_raw_power_state("SHELVED", vm_openstack2)

      post(api_vms_url, :params => gen_request(:shelve_offload, nil, vm_openstack1_url, vm_openstack2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm_openstack1), api_vm_url(nil, vm_openstack2)])
    end
  end

  context "Vm delete action" do
    it "deletes an invalid vm" do
      api_basic_authorize action_identifier(:vms, :delete)

      post(invalid_vm_url, :params => gen_request(:delete))

      expect(response).to have_http_status(:not_found)
    end

    it "deletes a vm via a resource POST without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:delete))

      expect(response).to have_http_status(:forbidden)
    end

    it "deletes a vm via a resource DELETE without appropriate role" do
      api_basic_authorize

      delete(invalid_vm_url)

      expect(response).to have_http_status(:forbidden)
    end

    it "deletes a vm via a resource POST" do
      api_basic_authorize action_identifier(:vms, :delete)

      post(vm_url, :params => gen_request(:delete))

      expect_single_action_result(:success => true, :message => /Deleting Vm id: #{vm.id}/, :href => api_vm_url(nil, vm), :task => true)
      expect(MiqQueue.where(:method_name => "destroy",
                            :user_id     => @user.id,
                            :group_id    => @user.current_group.id,
                            :tenant_id   => @user.current_tenant.id).count).to eq(1)
    end

    it "deletes a vm via a resource DELETE" do
      api_basic_authorize action_identifier(:vms, :delete)

      delete(vm_url)

      expect(response).to have_http_status(:no_content)
    end

    it "deletes multiple vms" do
      api_basic_authorize action_identifier(:vms, :delete)

      post(api_vms_url, :params => gen_request(:delete, nil, vm1_url, vm2_url))

      expect_multiple_action_result(2, :task => true)
    end
  end

  context "Vm set_owner action" do
    it "set_owner to an invalid vm" do
      api_basic_authorize action_identifier(:vms, :set_owner)

      post(invalid_vm_url, :params => gen_request(:set_owner, "owner" => "admin"))

      expect(response).to have_http_status(:not_found)
    end

    it "set_owner without appropriate action role" do
      api_basic_authorize

      post(vm_url, :params => gen_request(:set_owner, "owner" => "admin"))

      expect(response).to have_http_status(:forbidden)
    end

    it "set_owner with missing owner" do
      api_basic_authorize action_identifier(:vms, :set_owner)

      post(vm_url, :params => gen_request(:set_owner))

      expect_bad_request("Must specify an owner")
    end

    it "set_owner with invalid owner" do
      api_basic_authorize action_identifier(:vms, :set_owner)

      post(vm_url, :params => gen_request(:set_owner, "owner" => "bad_user"))

      expect_bad_request(/Invalid user/)
    end

    it "set_owner to a vm" do
      api_basic_authorize action_identifier(:vms, :set_owner)

      post(vm_url, :params => gen_request(:set_owner, "owner" => @user.userid))

      expect_single_action_result(:success => true, :message => /Setting owner/i, :href => api_vm_url(nil, vm))
      expect(vm.reload.evm_owner).to eq(@user)
    end

    it "set_owner to multiple vms" do
      api_basic_authorize action_identifier(:vms, :set_owner)

      post(api_vms_url, :params => gen_request(:set_owner, {"owner" => @user.userid}, vm1_url, vm2_url))

      expect_multiple_action_result(2, :success => true, :message => /Setting owner/i)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
      expect(vm1.reload.evm_owner).to eq(@user)
      expect(vm2.reload.evm_owner).to eq(@user)
    end
  end

  context "Vm custom_attributes" do
    let(:ca1) { FactoryBot.create(:custom_attribute, :name => "name1", :value => "value1") }
    let(:ca2) { FactoryBot.create(:custom_attribute, :name => "name2", :value => "value2") }
    let(:ca1_url)        { api_vm_custom_attribute_url(nil, vm, ca1) }
    let(:ca2_url)        { api_vm_custom_attribute_url(nil, vm, ca2) }

    it "getting custom_attributes from a vm with no custom_attributes" do
      api_basic_authorize

      get(api_vm_custom_attributes_url(nil, vm))

      expect_empty_query_result(:custom_attributes)
    end

    it "getting custom_attributes from a vm" do
      api_basic_authorize
      vm.custom_attributes = [ca1, ca2]

      get api_vm_custom_attributes_url(nil, vm)

      expect_query_result(:custom_attributes, 2)
      expect_result_resources_to_include_hrefs("resources",
                                               [api_vm_custom_attribute_url(nil, vm, ca1),
                                                api_vm_custom_attribute_url(nil, vm, ca2)])
    end

    it "getting custom_attributes from a vm in expanded form" do
      api_basic_authorize
      vm.custom_attributes = [ca1, ca2]

      get api_vm_custom_attributes_url(nil, vm), :params => { :expand => "resources" }

      expect_query_result(:custom_attributes, 2)
      expect_result_resources_to_include_data("resources", "name" => %w(name1 name2))
    end

    it "getting custom_attributes from a vm using expand" do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
      vm.custom_attributes = [ca1, ca2]

      get vm_url, :params => { :expand => "custom_attributes" }

      expect_single_resource_query("guid" => vm_guid)
      expect_result_resources_to_include_data("custom_attributes", "name" => %w(name1 name2))
    end

    it "delete a custom_attribute without appropriate role" do
      api_basic_authorize
      vm.custom_attributes = [ca1]

      post(api_vm_custom_attributes_url(nil, vm), :params => gen_request(:delete, nil, vm_url))

      expect(response).to have_http_status(:forbidden)
    end

    it "delete a custom_attribute from a vm via the delete action" do
      api_basic_authorize action_identifier(:vms, :edit)
      vm.custom_attributes = [ca1]

      post(api_vm_custom_attributes_url(nil, vm), :params => gen_request(:delete, nil, ca1_url))

      expect(response).to have_http_status(:ok)
      expect(vm.reload.custom_attributes).to be_empty
    end

    it "add custom attribute to a vm without a name" do
      api_basic_authorize action_identifier(:vms, :edit)

      post(api_vm_custom_attributes_url(nil, vm), :params => gen_request(:add, "value" => "value1"))

      expect_bad_request("Must specify a name")
    end

    it "add custom attributes to a vm" do
      api_basic_authorize action_identifier(:vms, :edit)

      post(api_vm_custom_attributes_url(nil, vm), :params => gen_request(:add, [{"name" => "name1", "value" => "value1"},
                                                                                {"name" => "name2", "value" => "value2"}]))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_data("results", "name" => %w(name1 name2))
      expect(vm.custom_attributes.size).to eq(2)
      expect(vm.custom_attributes.pluck(:value).sort).to eq(%w(value1 value2))
    end

    it "edit a custom attribute by name" do
      api_basic_authorize action_identifier(:vms, :edit)
      vm.custom_attributes = [ca1]

      post(api_vm_custom_attributes_url(nil, vm), :params => gen_request(:edit, "name" => "name1", "value" => "value one"))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_data("results", "value" => ["value one"])
      expect(vm.reload.custom_attributes.first.value).to eq("value one")
    end

    it "edit a custom attribute by href" do
      api_basic_authorize action_identifier(:vms, :edit)
      vm.custom_attributes = [ca1]

      post(api_vm_custom_attributes_url(nil, vm), :params => gen_request(:edit, "href" => ca1_url, "value" => "new value1"))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_data("results", "value" => ["new value1"])
      expect(vm.reload.custom_attributes.first.value).to eq("new value1")
    end

    it "edit multiple custom attributes" do
      api_basic_authorize action_identifier(:vms, :edit)
      vm.custom_attributes = [ca1, ca2]

      post(api_vm_custom_attributes_url(nil, vm), :params => gen_request(:edit, [{"name" => "name1", "value" => "new value1"},
                                                                                 {"name" => "name2", "value" => "new value2"}]))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_data("results", "value" => ["new value1", "new value2"])
      expect(vm.reload.custom_attributes.pluck(:value).sort).to eq(["new value1", "new value2"])
    end
  end

  context "Vm scan action" do
    it "scans an invalid vm" do
      api_basic_authorize action_identifier(:vms, :scan)

      post(invalid_vm_url, :params => gen_request(:scan))

      expect(response).to have_http_status(:not_found)
    end

    it "scans an invalid Vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:scan))

      expect(response).to have_http_status(:forbidden)
    end

    it "scan a Vm" do
      api_basic_authorize action_identifier(:vms, :scan)

      stub_supports(vm, :smartstate_analysis)

      post(vm_url, :params => gen_request(:scan))

      expect_single_action_result(:success => true, :message => /Scanning/i, :href => api_vm_url(nil, vm), :task => true)
    end

    it "scan a Vm that doesn't support smartstate_analysis" do
      api_basic_authorize action_identifier(:vms, :scan)

      stub_supports_not(vm, :smartstate_analysis)

      post(vm_url, :params => gen_request(:scan))

      expect_bad_request(/Feature not available\/supported/)
    end

    it "scan multiple Vms" do
      api_basic_authorize action_identifier(:vms, :scan)

      stub_supports(vm1, :smartstate_analysis)
      stub_supports(vm2, :smartstate_analysis)

      post(api_vms_url, :params => gen_request(:scan, nil, vm1_url, vm2_url))

      expect_multiple_action_result(2, :task => true)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
    end

    it "scan multiple Vms where at least one doesn't support smartstate_analysis" do
      api_basic_authorize action_identifier(:vms, :scan)

      stub_supports(vm1, :smartstate_analysis)
      stub_supports_not(vm_openstack, :smartstate_analysis)

      post(api_vms_url, :params => gen_request(:scan, nil, vm1_url, vm_openstack_url))

      expect(response).to have_http_status(:ok)

      expect(response.parsed_body["results"].first["message"]).to match(/Scanning Vm id: #{vm1.id} name: '#{vm1.name}'/)
      expect(response.parsed_body["results"].last["message"]).to match(/Feature not available\/supported/)
    end
  end

  context "Vm add_event action" do
    it "to an invalid vm" do
      api_basic_authorize action_identifier(:vms, :add_event)

      post(invalid_vm_url, :params => gen_request(:add_event))

      expect(response).to have_http_status(:not_found)
    end

    it "to an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:add_event))

      expect(response).to have_http_status(:forbidden)
    end

    it "to a single Vm" do
      api_basic_authorize collection_action_identifier(:vms, :add_event)

      post(vm_url, :params => gen_request(:add_event, :event_type => "special", :event_message => "message"))

      expect_single_action_result(:success => true, :message => /adding event/i, :href => api_vm_url(nil, vm))
    end

    it "to multiple Vms" do
      api_basic_authorize collection_action_identifier(:vms, :add_event)

      post(
        api_vms_url,
        :params => gen_request(
          :add_event,
          [{"href" => vm1_url, "event_type" => "etype1", "event_message" => "emsg1"},
           {"href" => vm2_url, "event_type" => "etype2", "event_message" => "emsg2"}]
        )
      )

      expect_multiple_action_result(2, :success => true, :message => /Adding Event/i)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
    end
  end

  context "Vm retire action" do
    context "retire_now" do
      it "to an invalid vm" do
        api_basic_authorize action_identifier(:vms, :retire)

        post(invalid_vm_url, :params => gen_request(:retire))

        expect(response).to have_http_status(:not_found)
      end

      it "to an invalid vm without appropriate role" do
        api_basic_authorize

        post(invalid_vm_url, :params => gen_request(:retire))

        expect(response).to have_http_status(:forbidden)
      end

      it "to a single Vm" do
        api_basic_authorize action_identifier(:vms, :retire)

        post(vm_url, :params => gen_request(:retire))

        expect_single_action_result(:success => true, :message => /Retiring.*#{vm.id}/i, :href => api_vm_url(nil, vm))
      end

      it "to multiple Vms" do
        api_basic_authorize collection_action_identifier(:vms, :retire)

        post(api_vms_url, :params => gen_request(:retire, [{"href" => vm1_url}, {"href" => vm2_url}]))

        expect_multiple_action_result(2, :success => true, :message => /Retiring/, :task_id => true)
        expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
      end

      it "in the future" do
        api_basic_authorize action_identifier(:vms, :retire)
        date = 2.weeks.from_now
        post(vm_url, :params => gen_request(:retire, :date => date.iso8601))

        expect_single_action_result(:success => true, :message => /Retiring.*#{vm.id}/i, :href => api_vm_url(nil, vm))
      end
    end

    context "request_retire" do
      context "valid" do
        it "to a single Vm" do
          api_basic_authorize(action_identifier(:vms, :request_retire))
          message = "name like 'Retiring%#{vm.id}%#{vm.name}%'"
          task_id = MiqTask.find_by(message)&.id
          expect(task_id).to be_nil

          post(vm_url, :params => gen_request(:request_retire))

          task = MiqTask.find_by(message)
          expect_single_action_result(:success => true, :message => /Retiring/, :href => api_vm_url(nil, vm), :task_id => task&.id)
          expect(task).not_to be_nil
        end

        it "in the future" do
          api_basic_authorize action_identifier(:vms, :request_retire)
          date = 2.weeks.from_now
          post(vm_url, :params => gen_request(:request_retire, :date => date.iso8601))

          expect_single_action_result(:success => true, :message => /Retiring.*#{vm.id}/i, :href => api_vm_url(nil, vm))
        end

        it "queues retirement task" do
          api_basic_authorize(action_identifier(:vms, :request_retire))
          message = "name like 'Retiring%#{vm.id}%#{vm.name}%'"
          task_id = MiqTask.find_by(message)&.id
          expect(task_id).to be_nil
          expect(MiqRequest.count).to eq(0)

          post(vm_url, :params => gen_request(:request_retire))

          task = MiqTask.find_by(message)
          MiqTask.find(task.id).miq_queue.deliver

          expect(MiqQueue.count).to eq(1)
        end

        it "to multiple Vms" do
          api_basic_authorize(collection_action_identifier(:vms, :request_retire))

          post(api_vms_url, :params => gen_request(:request_retire, [{"href" => vm1_url}, {"href" => vm2_url}]))

          expect_multiple_action_result(2, :success => true, :message => /Retiring/, :task_id => true)
          expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
        end
      end

      context "invalid" do
        it "to an invalid vm" do
          api_basic_authorize(action_identifier(:vms, :request_retire))

          post(invalid_vm_url, :params => gen_request(:request_retire))

          expect(response).to have_http_status(:not_found)
        end

        it "to an invalid vm with only basic auth" do
          api_basic_authorize

          post(invalid_vm_url, :params => gen_request(:request_retire))

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  context "Vm reset action" do
    it "to an invalid vm" do
      api_basic_authorize action_identifier(:vms, :reset)

      post(invalid_vm_url, :params => gen_request(:reset))

      expect(response).to have_http_status(:not_found)
    end

    it "to an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:reset))

      expect(response).to have_http_status(:forbidden)
    end

    it "to a single Vm" do
      api_basic_authorize action_identifier(:vms, :reset)

      post(vm_url, :params => gen_request(:reset))

      expect_single_action_result(:success => true, :message => /Resetting.*#{vm.id}/i, :href => api_vm_url(nil, vm), :task_id => true)
    end

    it "to multiple Vms" do
      api_basic_authorize collection_action_identifier(:vms, :reset)

      post(api_vms_url, :params => gen_request(:reset, [{"href" => vm1_url}, {"href" => vm2_url}]))

      expect_multiple_action_result(2, :success => true, :message => /Resetting/)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
    end
  end

  context "Vm shutdown guest action" do
    it "to an invalid vm" do
      api_basic_authorize action_identifier(:vms, :shutdown_guest)

      post(invalid_vm_url, :params => gen_request(:shutdown_guest))

      expect(response).to have_http_status(:not_found)
    end

    it "to an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:shutdown_guest))

      expect(response).to have_http_status(:forbidden)
    end

    it "to a single Vm" do
      api_basic_authorize action_identifier(:vms, :shutdown_guest)

      post(vm_url, :params => gen_request(:shutdown_guest))

      expect_single_action_result(:success => true, :message => /Shutting Down/i, :href => api_vm_url(nil, vm))
    end

    it "to multiple Vms" do
      api_basic_authorize collection_action_identifier(:vms, :shutdown_guest)

      post(api_vms_url, :params => gen_request(:shutdown_guest, [{"href" => vm1_url}, {"href" => vm2_url}]))

      expect_multiple_action_result(2, :success => true, :message => /Shutting Down/)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
    end
  end

  context "Vm refresh action" do
    it "to an invalid vm" do
      api_basic_authorize action_identifier(:vms, :refresh)

      post(invalid_vm_url, :params => gen_request(:refresh))

      expect(response).to have_http_status(:not_found)
    end

    it "to an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:refresh))

      expect(response).to have_http_status(:forbidden)
    end

    it "to a single Vm" do
      api_basic_authorize action_identifier(:vms, :refresh)

      post(vm_url, :params => gen_request(:refresh))

      expect_single_action_result(:success => true, :message => /Refreshing Vm.*#{vm.id}/i, :href => api_vm_url(nil, vm))
    end

    it "to multiple Vms" do
      api_basic_authorize collection_action_identifier(:vms, :refresh)

      post(api_vms_url, :params => gen_request(:refresh, [{"href" => vm1_url}, {"href" => vm2_url}]))

      expect_multiple_action_result(2, :success => true, :message => /Refreshing/)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
    end
  end

  context "Vm reboot guest action" do
    it "to an invalid vm" do
      api_basic_authorize action_identifier(:vms, :reboot_guest)

      post(invalid_vm_url, :params => gen_request(:reboot_guest))

      expect(response).to have_http_status(:not_found)
    end

    it "to an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:reboot_guest))

      expect(response).to have_http_status(:forbidden)
    end

    it "to a single Vm" do
      api_basic_authorize action_identifier(:vms, :reboot_guest)

      post(vm_url, :params => gen_request(:reboot_guest))

      expect_single_action_result(:success => true, :message => /Rebooting.*#{vm.id}/i, :href => api_vm_url(nil, vm))
    end

    it "to multiple Vms" do
      api_basic_authorize collection_action_identifier(:vms, :reboot_guest)

      post(api_vms_url, :params => gen_request(:reboot_guest, [{"href" => vm1_url}, {"href" => vm2_url}]))

      expect_multiple_action_result(2, :success => true, :message => /Rebooting/)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
    end
  end

  context "Vm rename action" do
    it "to an invalid vm" do
      api_basic_authorize action_identifier(:vms, :rename)

      post(invalid_vm_url, :params => gen_request(:rename, "new_name" => "test"))

      expect(response).to have_http_status(:not_found)
    end

    it "to an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:rename, "new_name" => "test"))

      expect(response).to have_http_status(:forbidden)
    end

    it "to a vm with missing new_name" do
      api_basic_authorize action_identifier(:vms, :rename)

      post(vm_url, :params => gen_request(:rename))

      expect_bad_request("Must specify a new_name")
    end

    it "to a single vm" do
      api_basic_authorize action_identifier(:vms, :rename)

      post(vm_url, :params => gen_request(:rename, "new_name" => "new_vm"))

      expect_single_action_result(:success => true, :message => /Renaming/i, :href => api_vm_url(nil, vm))
    end

    it "to multiple vms" do
      api_basic_authorize collection_action_identifier(:vms, :rename)

      post(api_vms_url, :params => gen_request(:rename, [{"href" => vm1_url, "new_name" => "new_1"}, {"href" => vm2_url, "new_name" => "new_2"}]))

      expect_multiple_action_result(2, :success => true, :message => /Renaming/i)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
    end
  end

  context "Vm set_description action" do
    it "to an invalid vm" do
      api_basic_authorize action_identifier(:vms, :set_description)

      post(invalid_vm_url, :params => gen_request(:set_description, "new_description" => "test"))

      expect(response).to have_http_status(:not_found)
    end

    it "to a valid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:set_description, "new_description" => "test"))

      expect(response).to have_http_status(:forbidden)
    end

    it "to a vm with missing new_description" do
      api_basic_authorize action_identifier(:vms, :set_description)

      post(vm_url, :params => gen_request(:set_description))

      expect_bad_request("Must specify a new_description")
    end

    it "to a single vm" do
      api_basic_authorize action_identifier(:vms, :set_description)

      post(vm_url, :params => gen_request(:set_description, "new_description" => "test"))

      expect_single_action_result(:success => true, :message => /Setting description for Vm id: #{vm.id}.* to test/i, :href => api_vm_url(nil, vm))
    end

    it "to multiple vms" do
      api_basic_authorize collection_action_identifier(:vms, :set_description)

      post(api_vms_url, :params => gen_request(:set_description, [{"href" => vm1_url, "new_description" => "test1"}, {"href" => vm2_url, "new_description" => "test2"}]))

      expect_multiple_action_result(2, :success => true, :task => true, :message => /Setting description for Vm.* to test[12]/i)
      expect_result_resources_to_include_hrefs("results", [api_vm_url(nil, vm1), api_vm_url(nil, vm2)])
    end
  end

  context "Vm request console action" do
    it "to an invalid vm" do
      api_basic_authorize action_identifier(:vms, :request_console)

      post(invalid_vm_url, :params => gen_request(:request_console))

      expect(response).to have_http_status(:not_found)
    end

    it "to an invalid vm without appropriate role" do
      api_basic_authorize

      post(invalid_vm_url, :params => gen_request(:request_console))

      expect(response).to have_http_status(:forbidden)
    end

    context "to a single Vm" do
      let(:auth) { FactoryBot.create(:authentication, :authtype => "console") }
      let(:ems)  { FactoryBot.create(:ems_vmware, :authentications => [auth]) }
      let!(:vm)  { FactoryBot.create(:vm_vmware, :ext_management_system => ems) }

      it "returns success" do
        api_basic_authorize action_identifier(:vms, :request_console)

        post(api_vm_url(nil, vm), :params => gen_request(:request_console))

        expect_single_action_result(:success => true, :message => /Requesting Console.*#{vm.id}/i, :href => api_vm_url(nil, vm))
      end

      it "defaults to vnc" do
        api_basic_authorize action_identifier(:vms, :request_console)

        post(api_vm_url(nil, vm), :params => gen_request(:request_console))

        queue_item = MiqQueue.find_by(:class_name => vm.class.name, :method_name => "remote_console_acquire_ticket")
        expect(queue_item.args.last).to eq("vnc")
      end

      context "with protocol: native" do
        context "with a vm that doesn't support it" do
          it "returns a failure" do
            api_basic_authorize action_identifier(:vms, :request_console)

            post(api_vm_url(nil, vm), :params => gen_request(:request_console, :protocol => "native"))
            expect_single_action_result(:success => false, :message => /Console protocol native is not supported/, :href => api_vm_url(nil, vm))
          end
        end

        context "with a vm that supports it" do
          let!(:vm) { FactoryBot.create(:vm_redhat, :ext_management_system => ems) }

          it "returns success" do
            api_basic_authorize action_identifier(:vms, :request_console)

            post(api_vm_url(nil, vm), :params => gen_request(:request_console, :protocol => "native"))

            expect_single_action_result(:success => true, :message => /Requesting Native Console.*#{vm.id}/i, :href => api_vm_url(nil, vm))

            expect(MiqQueue.find_by(:class_name => vm.class.name, :method_name => "native_console_connection")).not_to be_nil
          end

          context "but is not connected to a provider" do
            let!(:vm) { FactoryBot.create(:vm_redhat, :ext_management_system => nil) }

            it "returns a failure" do
              api_basic_authorize action_identifier(:vms, :request_console)

              post(api_vm_url(nil, vm), :params => gen_request(:request_console, :protocol => "native"))
              expect_single_action_result(:success => false, :message => /Remote viewer requires the vm to be registered with a management system/, :href => api_vm_url(nil, vm))
            end
          end

          context "but is not running" do
            let!(:vm) { FactoryBot.create(:vm_redhat, :ext_management_system => ems, :raw_power_state => "down") }

            it "returns a failure" do
              api_basic_authorize action_identifier(:vms, :request_console)

              post(api_vm_url(nil, vm), :params => gen_request(:request_console, :protocol => "native"))
              expect_single_action_result(:success => false, :message => /Remote viewer requires the vm to be running./, :href => api_vm_url(nil, vm))
            end
          end
        end
      end
    end
  end

  it_behaves_like "a check compliance action", "vm", :vm_vmware, "Vm"
  it_behaves_like "simulate policy action", "vm", :vm_vmware, "request_vm_poweroff"

  context "Vm Tag subcollection" do
    let(:tag1)         { {:category => "department", :name => "finance", :path => "/managed/department/finance"} }
    let(:tag2)         { {:category => "cc",         :name => "001",     :path => "/managed/cc/001"} }

    let(:vm1) { FactoryBot.create(:vm_vmware, :host => host, :ems_id => ems.id, :raw_power_state => "poweredOn") }
    let(:vm1_url) { api_vm_url(nil, vm1) }

    let(:vm2) { FactoryBot.create(:vm_vmware, :host => host, :ems_id => ems.id, :raw_power_state => "poweredOn") }
    let(:vm2_url) { api_vm_url(nil, vm2) }

    let(:invalid_tag_url) { api_tag_url(nil, 999_999) }

    before do
      FactoryBot.create(:classification_department_with_tags)
      FactoryBot.create(:classification_cost_center_with_tags)
      Classification.classify(vm2, tag1[:category], tag1[:name])
      Classification.classify(vm2, tag2[:category], tag2[:name])
    end

    it "query all tags of a Vm with no tags" do
      api_basic_authorize

      get api_vm_tags_url(nil, vm1)

      expect_empty_query_result(:tags)
    end

    it "query all tags of a Vm" do
      api_basic_authorize

      get api_vm_tags_url(nil, vm2)

      expect_query_result(:tags, 2, Tag.count)
    end

    it "query all tags of a Vm and verify tag category and names" do
      api_basic_authorize

      get api_vm_tags_url(nil, vm2), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => [tag1[:path], tag2[:path]])
    end

    it "query vms by tag name via filter[]=tags.name" do
      api_basic_authorize collection_action_identifier(:vms, :read, :get)
      # let's make sure both vms are created
      vm1
      vm2

      get api_vms_url, :params => { :expand => "resources", :filter => ["tags.name='#{tag2[:path]}'"] }

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_include_hrefs("resources", [api_vm_url(nil, vm2)])
    end

    it "handles counts properly with virtual_attributes" do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
      get api_vms_url, :params => {
        :expand     => "resources",
        :filter     => ["ems_id!=null"],
        :attributes => "name,provisioned_storage"
      }

      expect(response.parsed_body["subcount"]).to eq 1
    end

    it "assigns a tag to a Vm without appropriate role" do
      api_basic_authorize

      post(api_vm_tags_url(nil, vm1), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Vm" do
      api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

      post(api_vm_tags_url(nil, vm1), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(
        [{:success => true, :href => api_vm_url(nil, vm1), :tag_category => tag1[:category], :tag_name => tag1[:name]}]
      )
    end

    it "assigns a tag to a Vm by name path" do
      api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

      post(api_vm_tags_url(nil, vm1), :params => gen_request(:assign, :name => tag1[:path]))

      expect_tagging_result(
        [{:success => true, :href => api_vm_url(nil, vm1), :tag_category => tag1[:category], :tag_name => tag1[:name]}]
      )
    end

    it "assigns a tag to a Vm by href" do
      api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

      post(api_vm_tags_url(nil, vm1), :params => gen_request(:assign, :href => api_tag_url(nil, Tag.find_by(:name => tag1[:path]))))

      expect_tagging_result(
        [{:success => true, :href => api_vm_url(nil, vm1), :tag_category => tag1[:category], :tag_name => tag1[:name]}]
      )
    end

    it "assigns an invalid tag by href to a Vm" do
      api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

      post(api_vm_tags_url(nil, vm1), :params => gen_request(:assign, :href => invalid_tag_url))

      expect(response).to have_http_status(:not_found)
    end

    it "assigns an invalid tag to a Vm" do
      api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

      post(api_vm_tags_url(nil, vm1), :params => gen_request(:assign, :name => "/managed/bad_category/bad_name"))

      expect_tagging_result(
        [{:success => false, :href => api_vm_url(nil, vm1), :tag_category => "bad_category", :tag_name => "bad_name"}],
        :bad_request
      )
    end

    it "assigns multiple tags to a Vm" do
      api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

      post(api_vm_tags_url(nil, vm1), :params => gen_request(:assign, [{:name => tag1[:path]}, {:name => tag2[:path]}]))

      expect_tagging_result(
        [{:success => true, :href => api_vm_url(nil, vm1), :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => api_vm_url(nil, vm1), :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      )
    end

    it "assigns tags by mixed specification to a Vm" do
      api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

      tag = Tag.find_by(:name => tag2[:path])
      post(api_vm_tags_url(nil, vm1), :params => gen_request(:assign, [{:name => tag1[:path]}, {:href => api_tag_url(nil, tag)}]))

      expect_tagging_result(
        [{:success => true, :href => api_vm_url(nil, vm1), :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => api_vm_url(nil, vm1), :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      )
    end

    it "unassigns a tag from a Vm without appropriate role" do
      api_basic_authorize

      post(api_vm_tags_url(nil, vm1), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Vm" do
      api_basic_authorize subcollection_action_identifier(:vms, :tags, :unassign)

      post(api_vm_tags_url(nil, vm2), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(
        [{:success => true, :href => api_vm_url(nil, vm2), :tag_category => tag1[:category], :tag_name => tag1[:name]}]
      )
      expect(vm2.tags.count).to eq(1)
      expect(vm2.tags.first.name).to eq(tag2[:path])
    end

    it "unassigns multiple tags from a Vm" do
      api_basic_authorize subcollection_action_identifier(:vms, :tags, :unassign)

      tag = Tag.find_by(:name => tag2[:path])
      post(api_vm_tags_url(nil, vm2), :params => gen_request(:unassign, [{:name => tag1[:path]}, {:href => api_tag_url(nil, tag)}]))

      expect_tagging_result(
        [{:success => true, :href => api_vm_url(nil, vm2), :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => api_vm_url(nil, vm2), :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      )
      expect(vm2.tags.count).to eq(0)
    end
  end

  describe "custom actions" do
    it "renders custom actions" do
      vm = FactoryBot.create(:vm_vmware)
      FactoryBot.create(
        :custom_button_set,
        :members => [FactoryBot.create(:custom_button, :name => "test button", :applies_to_class => "Vm")],
      )
      api_basic_authorize(action_identifier(:vms, :read, :resource_actions, :get))

      get(api_vm_url(nil, vm))

      expected = {
        "actions" => a_collection_including(
          a_hash_including("name" => "test button")
        )
      }
      expect(response.parsed_body).to include(expected)
    end

    it "renders the custom actions when requested" do
      vm = FactoryBot.create(:vm_vmware)
      FactoryBot.create(
        :custom_button_set,
        :name    => "test button group",
        :members => [FactoryBot.create(:custom_button, :name => "test button", :applies_to_class => "Vm")]
      )
      api_basic_authorize(action_identifier(:vms, :read, :resource_actions, :get))

      get(api_vm_url(nil, vm), :params => { :attributes => "custom_actions" })

      expected = {
        "custom_actions" => a_hash_including(
          "button_groups" => [
            a_hash_including(
              "name"    => "test button group",
              "buttons" => [
                a_hash_including("name" => "test button")
              ]
            )
          ]
        )
      }
      expect(response.parsed_body).to include(expected)
    end

    it "renders the custom action buttons when requested" do
      vm = FactoryBot.create(:vm_vmware)
      FactoryBot.create(
        :custom_button_set,
        :members => [FactoryBot.create(:custom_button, :name => "test button", :applies_to_class => "Vm")]
      )
      api_basic_authorize(action_identifier(:vms, :read, :resource_actions, :get))

      get(api_vm_url(nil, vm), :params => { :attributes => "custom_action_buttons" })

      expected = {
        "custom_action_buttons" => a_collection_containing_exactly(
          a_hash_including("name" => "test button"),
        )
      }
      expect(response.parsed_body).to include(expected)
    end

    it "can execute a custom action" do
      vm = FactoryBot.create(:vm_vmware)
      FactoryBot.create(
        :custom_button_set,
        :members => [
          FactoryBot.create(
            :custom_button,
            :name             => "test button",
            :applies_to_class => "Vm",
            :resource_action  => FactoryBot.create(:resource_action)
          )
        ]
      )
      api_basic_authorize

      post(api_vm_url(nil, vm), :params => { :action => "test button", :button_key1 => "foo" })

      expected = {
        "success" => true,
        "message" => "Invoked custom action test button for vms id: #{vm.id}",
        "href"    => api_vm_url(nil, vm)
      }
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "set_miq_server action" do
    let(:server) { FactoryBot.create(:miq_server) }
    let(:server2) { FactoryBot.create(:miq_server) }

    it "does not allow setting an miq_server without an appropriate role" do
      api_basic_authorize

      post(api_vm_url(nil, vm), :params => { :action => 'set_miq_server' })

      expect(response).to have_http_status(:forbidden)
    end

    it "sets an miq server" do
      api_basic_authorize action_identifier(:vms, :set_miq_server)

      post(api_vm_url(nil, vm), :params => { :action => 'set_miq_server', :miq_server => { :href => api_server_url(nil, server)} })

      expect_single_action_result(:success => true, :message => /Setting miq_server for Vm id: #{vm.id} name: '#{vm.name}'/)
      expect(vm.reload.miq_server).to eq(server)
    end

    it "can set multiple miq servers" do
      api_basic_authorize collection_action_identifier(:vms, :set_miq_server)

      post(
        api_vms_url,
        :params => {
          :action    => 'set_miq_server',
          :resources => [
            { :id => vm.id, :miq_server => { :href => api_server_url(nil, server) } },
            { :id => vm1.id, :miq_server => { :id => server2.id }}
          ]
        }
      )

      expect_multiple_action_result(2, :success => true, :message => /Setting miq_server for Vm/i)
      expect(vm.reload.miq_server).to eq(server)
      expect(vm1.reload.miq_server).to eq(server2)
    end

    it "raises an error unless a valid miq_server reference is specified" do
      api_basic_authorize action_identifier(:vms, :set_miq_server)

      post(api_vm_url(nil, vm), :params => { :action => 'set_miq_server', :miq_server => { :href => api_vm_url(nil, 1) } })
      expect_bad_request(/Must specify a valid miq_server href or id/)

      post(api_vm_url(nil, vm), :params => { :action => 'set_miq_server', :miq_server => { :id => nil } })
      expect_bad_request(/Must specify a valid miq_server href or id/)
    end

    it "can unassign a server if an empty hash is passed" do
      vm.miq_server = server
      api_basic_authorize action_identifier(:vms, :set_miq_server)

      post(api_vm_url(nil, vm), :params => { :action => 'set_miq_server', :miq_server => {} })

      expect_single_action_result(:success => true, :message => "Removing miq_server from Vm id: #{vm.id} name: '#{vm.name}'")
    end
  end

  describe "metrics subcollection" do
    let(:url) { api_vm_metrics_url(nil, vm) }

    before do
      FactoryBot.create_list(:metric_vm_rt, 3, :resource => vm)
    end

    it 'returns the metrics for the vm' do
      api_basic_authorize subcollection_action_identifier(:vms, :metrics, :read, :get)

      get(url, :params => {:start_date => Time.zone.today.to_s})

      expected = {
        'count'    => 3,
        'subcount' => 3,
        'pages'    => 1
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
      expect(response.parsed_body['links'].keys).to match_array(%w[self first last])
    end

    it 'will not return metrics without an appropriate role' do
      api_basic_authorize

      get(url, :params => {:start_date => Time.zone.today.to_s})

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "metric rollups subcollection" do
    let(:url) { api_vm_metric_rollups_url(nil, vm) }

    before do
      FactoryBot.create_list(:metric_rollup_vm_hr, 3, :resource => vm)
      FactoryBot.create_list(:metric_rollup_vm_daily, 1, :resource => vm)
      FactoryBot.create_list(:metric_rollup_vm_hr, 1, :resource => vm1)
    end

    it 'returns the metric rollups for the vm' do
      api_basic_authorize subcollection_action_identifier(:vms, :metric_rollups, :read, :get)

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
  end

  context 'security groups subcollection' do
    before do
      @network_port = FactoryBot.create(:network_port, :device => vm_openstack)
      @security_group = FactoryBot.create(:security_group, :cloud_tenant => @cloud_tenant)
      @network_port_security_group = FactoryBot.create(:network_port_security_group,
                                                        :network_port   => @network_port,
                                                        :security_group => @security_group)
    end

    it 'queries all security groups from a vm' do
      api_basic_authorize subcollection_action_identifier(:vms, :security_groups, :read, :get)

      get(api_vm_security_groups_url(nil, vm_openstack))

      expected = {
        'resources' => [
          { 'href' => api_vm_security_group_url(nil, vm_openstack, @security_group) }
        ]

      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "will not show a vm's security groups without the appropriate role" do
      api_basic_authorize

      get(api_vm_security_groups_url(nil, vm_openstack))

      expect(response).to have_http_status(:forbidden)
    end

    it 'queries a single security group' do
      api_basic_authorize action_identifier(:security_groups, :read, :subresource_actions, :get)

      get(api_vm_security_group_url(nil, vm_openstack, @security_group))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => @security_group.id.to_s)
    end

    it "will not show a vm's security group without the appropriate role" do
      api_basic_authorize

      get(api_vm_security_group_url(nil, vm_openstack, @security_group))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "/api/vms/:id/options" do
    it 'returns the snapshot DDF schema for the given VM' do
      api_basic_authorize

      vm = FactoryBot.create(:vm_vmware)

      options(api_vm_snapshots_url(nil, vm))

      expect(response.parsed_body['data']['snapshot_form_schema']).to be_kind_of(Hash)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/vms/:id" do
    let(:ems) { FactoryBot.create(:ems_openstack) }
    let(:tenant) { FactoryBot.create(:cloud_tenant_openstack, :ext_management_system => ems) }
    let(:floating_ip) { FactoryBot.create(:floating_ip_openstack, :ext_management_system => ems.network_manager, :cloud_tenant => tenant) }

    it 'associates a floating ip to the vm' do
      vm = FactoryBot.create(:vm_openstack, :ems_id => ems.id, :cloud_tenant => tenant)
      api_basic_authorize action_identifier(:vms, :associate)

      post(api_vms_url, :params => {:action => 'associate', :resource => {:id => vm.id, :floating_ip => floating_ip}})

      expect(response).to have_http_status(:ok)
      task_id = response.parsed_body["task_id"]
      expected = {
        "results" => [{
          "message" => "Associating resource to Vm id: #{vm.id} name: '#{vm.name}",
          "success" => true,
          "task_id" => "#{task_id}",
        }]
      }
      expect_single_action_result(expected)
    end

    it 'associates a second floating ip to the vm' do
      ## Test
      floating_ip_2 = FactoryBot.create(:floating_ip_openstack, :ext_management_system => ems.network_manager, :cloud_tenant => tenant)
      vm = FactoryBot.create(:vm_openstack, :ems_id => ems.id, :cloud_tenant => tenant, :floating_ips => [floating_ip])
      api_basic_authorize action_identifier(:vms, :associate)

      post(api_vms_url, :params => {:action => 'associate', :resource => {:id => vm.id, :floating_ip => floating_ip_2}})

      expect(response).to have_http_status(:ok)
      task_id = response.parsed_body["task_id"]
      expected = {
        "results" => [{
          "message" => "Disassociating resource to Vm id: #{vm.id} name: '#{vm.name}",
          "success" => true,
          "task_id" => "#{task_id}",
        }]
      }
      expect_single_action_result(expected)
    end

    it 'disassociates a floating ip from the vm' do
      vm = FactoryBot.create(:vm_openstack, :ems_id => ems.id, :cloud_tenant => tenant, :floating_ips => [floating_ip])
      api_basic_authorize action_identifier(:vms, :disassociate)

      post(api_vms_url, :params => {:action => 'disassociate', :resource => {:id => vm.id, :floating_ip => floating_ip}})

      expect(response).to have_http_status(:ok)
      task_id = response.parsed_body["task_id"]
      expected = {
        "results" => [{
          "message" => "Disassociating resource to Vm id: #{vm.id} name: '#{vm.name}",
          "success" => true,
          "task_id" => "#{task_id}",
        }]
      }
      expect_single_action_result(expected)
    end
  end

  describe "/api/vms central admin" do
    let(:resource_type) { "vm" }

    include_examples "resource power operations", :vm_vmware, :reboot_guest
    include_examples "resource power operations", :vm_vmware, :rename
    include_examples "resource power operations", :vm_vmware, :reset
    include_examples "resource power operations", :vm_vmware, :shutdown_guest
    include_examples "resource power operations", :vm_vmware, :start
    include_examples "resource power operations", :vm_vmware, :stop
    include_examples "resource power operations", :vm_vmware, :suspend
  end
end
