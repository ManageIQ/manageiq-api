#
# REST API Querying capabilities
#   - Paging                - offset, limit
#   - Sorting               - sort_by=:attr, sort_oder = asc|desc
#   - Filtering             - filter[]=...
#   - Selecting Attributes  - attributes=:attr1,:attr2,...
#   - Querying by Tag       - by_tag=:tag_path  (i.e. /department/finance)
#   - Expanding Results     - expand=resources,:subcollection
#   - Resource actions
#
describe "Querying" do
  def create_vms_by_name(names)
    names.each.collect { |name| FactoryBot.create(:vm_vmware, :name => name) }
  end

  let(:vm1) { FactoryBot.create(:vm_vmware, :name => "vm1") }

  describe "Querying vms" do
    before { api_basic_authorize collection_action_identifier(:vms, :read, :get) }

    it "supports offset" do
      create_vms_by_name(%w(aa bb cc))

      get api_vms_url, :params => { :offset => 2 }

      expect_query_result(:vms, 1, 3)
    end

    it "supports limit" do
      create_vms_by_name(%w(aa bb cc))

      get api_vms_url, :params => { :limit => 2 }

      expect_query_result(:vms, 2, 3)
    end

    specify "a user cannot exceed the maximum allowed page size" do
      stub_settings_merge(:api => {:max_results_per_page => 2})
      FactoryBot.create_list(:vm, 3)

      get api_vms_url, :params => { :limit => 3 }

      expect(response.parsed_body).to include("count" => 3, "subcount" => 2)
    end

    it "supports offset and limit" do
      create_vms_by_name(%w(aa bb cc))

      get api_vms_url, :params => { :offset => 1, :limit => 1 }

      expect_query_result(:vms, 1, 3)
    end

    it "supports paging via offset and limit" do
      create_vms_by_name %w(aa bb cc dd ee)

      get api_vms_url, :params => { :offset => 0, :limit => 2, :sort_by => "name", :expand => "resources" }

      expect_query_result(:vms, 2, 5)
      expect_result_resources_to_match_hash([{"name" => "aa"}, {"name" => "bb"}])

      get api_vms_url, :params => { :offset => 2, :limit => 2, :sort_by => "name", :expand => "resources" }

      expect_query_result(:vms, 2, 5)
      expect_result_resources_to_match_hash([{"name" => "cc"}, {"name" => "dd"}])

      get api_vms_url, :params => { :offset => 4, :limit => 2, :sort_by => "name", :expand => "resources" }

      expect_query_result(:vms, 1, 5)
      expect_result_resources_to_match_hash([{"name" => "ee"}])
    end

    it 'raises a BadRequestError for attributes that do not exist' do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)

      get(api_vm_url(nil, vm1), :params => { :attributes => 'not_an_attribute' })

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => "Invalid attributes specified: not_an_attribute"
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns only id attributes if specified on a collection' do
      vm = FactoryBot.create(:vm)

      get(api_vms_url, :params => { :expand => :resources, :attributes => 'id' })

      expected = {
        'resources' => [{'href' => api_vm_url(nil, vm), 'id' => vm.id.to_s}]
      }
      expect(response.parsed_body).to include(expected)
    end

    it 'returns only id attributes if specified on a resource' do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)

      get(api_vm_url(nil, vm1), :params => { :attributes => 'id' })

      expect(response.parsed_body).to eq("href" => api_vm_url(nil, vm1), "id" => vm1.id.to_s)
    end

    it 'returns nil attributes when querying a resource' do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)

      get(api_vm_url(nil, vm1))

      expect(response.parsed_body).to include("id" => vm1.id.to_s, "retired" => nil, "smart" => nil)
    end

    it 'returns nil virtual attributes when querying a resource' do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)

      get(api_vm_url(nil, vm1), :params => {:attributes => 'vmsafe_agent_port'})

      expect(response.parsed_body).to include("id" => vm1.id.to_s, "vmsafe_agent_port" => nil)
    end

    it 'returns nil relationships when querying a resource' do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)

      get(api_vm_url(nil, vm1), :params => {:attributes => 'direct_service'})

      expect(response.parsed_body).to include("id" => vm1.id.to_s, "direct_service" => nil)
    end

    it 'returns nil attributes of relationships when querying a resource' do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)

      zone = FactoryBot.create(:zone, :name => "query_zone")
      vm   = FactoryBot.create(:vm_vmware, :host => FactoryBot.create(:host), :ems_id => FactoryBot.create(:ems_vmware, :zone => zone).id)

      get(api_vm_url(nil, vm), :params => {:attributes => 'ext_management_system.last_compliance_status'})

      expect(response.parsed_body).to include("id" => vm.id.to_s, "ext_management_system" => {"last_compliance_status" => nil})
    end

    it 'returns empty array for one-to-many relationships when querying a resource' do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)

      get(api_vm_url(nil, vm1), :params => {:attributes => 'files'})

      expect(response.parsed_body).to include("id" => vm1.id.to_s, "files" => [])
    end

    it "returns correct paging links" do
      create_vms_by_name %w(bb ff aa cc ee gg dd)

      get api_vms_url, :params => { :offset => 0, :limit => 2, :sort_by => "name", :expand => "resources" }

      expect_query_result(:vms, 2, 7)
      expect_result_resources_to_match_hash([{"name" => "aa"}, {"name" => "bb"}])
      expect(response.parsed_body["links"].keys).to match_array(%w(self first next last))
      links = response.parsed_body["links"]

      get(links["self"])

      expect_query_result(:vms, 2, 7)
      expect_result_resources_to_match_hash([{"name" => "aa"}, {"name" => "bb"}])

      get(links["next"])

      expect_query_result(:vms, 2, 7)
      expect_result_resources_to_match_hash([{"name" => "cc"}, {"name" => "dd"}])
      expect(response.parsed_body["links"].keys).to match_array(%w(self next previous first last))

      get(links["last"])

      expect_query_result(:vms, 1, 7)
      expect_result_resources_to_match_hash([{"name" => "gg"}])
      previous = response.parsed_body["links"]["previous"]
      expect(response.parsed_body["links"].keys).to match_array(%w(self previous first last))

      get(previous)

      expect_query_result(:vms, 2, 7)
      expect_result_resources_to_match_hash([{"name" => "ee"}, {"name" => "ff"}])

      get api_vms_url, :params => { :offset => 4, :limit => 3, :sort_by => "name", :expand => "resources" }

      expect_query_result(:vms, 3, 7)
      expect_result_resources_to_match_hash([{"name" => "ee"}, {"name" => "ff"}, {"name" => "gg"}])
      expect(response.parsed_body["links"].keys).to match_array(%w(self previous first last))
    end

    it "returns `self`, `first` and `last` links when result set size < max results" do
      create_vms_by_name %w(aa bb)

      get api_vms_url

      expect(response.parsed_body).to include("links" => a_hash_including("self", "first", "last"))
    end

    it "returns the correct page count" do
      create_vms_by_name %w(aa bb cc dd)

      get api_vms_url, :params => { :offset => 0, :limit => 2 }

      expect(response.parsed_body['pages']).to eq(2)

      get api_vms_url, :params => { :offset => 0, :limit => 3 }

      expect(response.parsed_body['pages']).to eq(2)

      get api_vms_url, :params => { :offset => 0, :limit => 4 }
      expect(response.parsed_body['subquery_count']).to be_nil
      expect(response.parsed_body['pages']).to eq(1)

      get api_vms_url, :params => { :offset => 0, :limit => 4, :filter => ["name='aa'", "or name='bb'"] }
      expect(response.parsed_body['subquery_count']).to eq(2)
      expect(response.parsed_body['pages']).to eq(1)
    end

    it "returns the correct pages if filters are specified" do
      create_vms_by_name %w(aa bb cc)

      get api_vms_url, :params => { :sort_by => "name", :filter => ["name='aa'", "or name='bb'"], :expand => "resources", :offset => 0, :limit => 1 }

      expect_query_result(:vms, 1, 3)
      expect_result_resources_to_match_hash([{"name" => "aa"}])
      expect(response.parsed_body["links"].keys).to match_array(%w(self next first last))

      get response.parsed_body["links"]["next"]

      expect_query_result(:vms, 1, 3)
      expect_result_resources_to_match_hash([{"name" => "bb"}])

      expect(response.parsed_body["links"].keys).to match_array(%w(self previous first last))
    end

    it "returns the correct subquery_count" do
      create_vms_by_name %w(aa bb cc dd)

      get api_vms_url, :params => { :sort_by => "name", :filter => ["name='aa'", "or name='bb'", "or name='dd'"], :expand => "resources", :offset => 0, :limit => 1 }

      expect(response.parsed_body["subquery_count"]).to eq(3)
      expect_query_result(:vms, 1, 4)
    end
  end

  describe "Sorting vms by attribute" do
    before { api_basic_authorize collection_action_identifier(:vms, :read, :get) }

    %w[asc ascending].each do |sort_order|
      it "orders with sort_order of #{sort_order}" do
        create_vms_by_name %w[cc aa bb]

        get api_vms_url, :params => {:sort_by => "name", :sort_order => sort_order, :expand => "resources"}

        expect_query_result(:vms, 3, 3)
        expect_result_resources_to_match_hash([{"name" => "aa"}, {"name" => "bb"}, {"name" => "cc"}])
      end
    end

    %w[desc descending].each do |sort_order|
      it "orders with sort_order of #{sort_order}" do
        create_vms_by_name %w[cc aa bb]

        get api_vms_url, :params => {:sort_by => "name", :sort_order => sort_order, :expand => "resources"}

        expect_query_result(:vms, 3, 3)
        expect_result_resources_to_match_hash([{"name" => "cc"}, {"name" => "bb"}, {"name" => "aa"}])
      end
    end

    it "supports case insensitive ordering" do
      create_vms_by_name %w(B c a)

      get api_vms_url, :params => { :sort_by => "name", :sort_order => "asc", :sort_options => "ignore_case", :expand => "resources" }

      expect_query_result(:vms, 3, 3)
      expect_result_resources_to_match_hash([{"name" => "a"}, {"name" => "B"}, {"name" => "c"}])
    end

    it "supports sorting with physical attributes" do
      FactoryBot.create(:vm_vmware, :vendor => "vmware", :name => "vmware_vm")
      FactoryBot.create(:vm_redhat, :vendor => "redhat", :name => "redhat_vm")

      get api_vms_url, :params => { :sort_by => "vendor", :sort_order => "asc", :expand => "resources" }

      expect_query_result(:vms, 2, 2)
      expect_result_resources_to_match_hash([{"name" => "redhat_vm"}, {"name" => "vmware_vm"}])
    end

    it 'supports sql friendly virtual attributes' do
      host_foo =  FactoryBot.create(:host, :name => 'foo')
      host_bar =  FactoryBot.create(:host, :name => 'bar')
      host_zap =  FactoryBot.create(:host, :name => 'zap')
      FactoryBot.create(:vm, :name => 'vm_foo', :host => host_foo)
      FactoryBot.create(:vm, :name => 'vm_bar', :host => host_bar)
      FactoryBot.create(:vm, :name => 'vm_zap', :host => host_zap)

      get api_vms_url, :params => { :sort_by => 'host_name', :sort_order => 'desc', :expand => 'resources' }

      expect_query_result(:vms, 3, 3)
      expect_result_resources_to_match_hash([{'name' => 'vm_zap'}, {'name' => 'vm_foo'}, {'name' => 'vm_bar'}])
    end

    it 'does not support non sql friendly virtual attributes' do
      FactoryBot.create(:vm)

      get api_vms_url, :params => { :sort_by => 'aggressive_recommended_mem', :sort_order => 'asc' }

      expected = {
        'error' => a_hash_including(
          'message' => 'Vm cannot be sorted by aggressive_recommended_mem'
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'allows sorting by asc when other filters are applied' do
      api_basic_authorize collection_action_identifier(:services, :read, :get)
      svc1, _svc2 = FactoryBot.create_list(:service, 2)
      dept = FactoryBot.create(:classification_department)
      FactoryBot.create(:classification_tag, :name => 'finance', :parent => dept)
      Classification.classify(svc1, 'department', 'finance')

      get(
        api_services_url,
        :params => {
          :sort_by    => 'created_at',
          :filter     => ['tags.name=/managed/department/finance'],
          :sort_order => 'asc',
          :limit      => 20,
          :offset     => 0
        }
      )

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['subcount']).to eq(1)
    end
  end

  describe "Filtering vms" do
    before { api_basic_authorize collection_action_identifier(:vms, :read, :get) }

    it "supports attribute equality test using double quotes" do
      _vm1, vm2 = create_vms_by_name(%w(aa bb))

      get api_vms_url, :params => { :expand => "resources", :filter => ['name="bb"'] }

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm2.name, "guid" => vm2.guid}])
    end

    it "supports attribute equality test using single quotes" do
      vm1, _vm2 = create_vms_by_name(%w(aa bb))

      get api_vms_url, :params => { :expand => "resources", :filter => ["name='aa'"] }

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm1.name, "guid" => vm1.guid}])
    end

    it "supports attribute pattern matching via %" do
      vm1, _vm2, vm3 = create_vms_by_name(%w(aa_B2 bb aa_A1))

      get api_vms_url, :params => { :expand => "resources", :filter => ["name='aa%'"], :sort_by => "name" }

      expect_query_result(:vms, 2, 3)
      expect_result_resources_to_match_hash([{"name" => vm3.name, "guid" => vm3.guid},
                                             {"name" => vm1.name, "guid" => vm1.guid}])
    end

    it "supports attribute pattern matching via *" do
      vm1, _vm2, vm3 = create_vms_by_name(%w(aa_B2 bb aa_A1))

      get api_vms_url, :params => { :expand => "resources", :filter => ["name='aa*'"], :sort_by => "name" }

      expect_query_result(:vms, 2, 3)
      expect_result_resources_to_match_hash([{"name" => vm3.name, "guid" => vm3.guid},
                                             {"name" => vm1.name, "guid" => vm1.guid}])
    end

    it "supports inequality test via !=" do
      vm1, _vm2, vm3 = create_vms_by_name(%w(aa bb cc))

      get api_vms_url, :params => { :expand => "resources", :filter => ["name!='b%'"], :sort_by => "name" }

      expect_query_result(:vms, 2, 3)
      expect_result_resources_to_match_hash([{"name" => vm1.name, "guid" => vm1.guid},
                                             {"name" => vm3.name, "guid" => vm3.guid}])
    end

    it "supports NULL/nil equality test via =" do
      vm1, vm2 = create_vms_by_name(%w(aa bb))
      vm2.update!(:retired => true)

      get api_vms_url, :params => { :expand => "resources", :filter => ["retired=NULL"] }

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm1.name, "guid" => vm1.guid}])
    end

    it "supports NULL/nil inequality test via !=" do
      _vm1, vm2 = create_vms_by_name(%w(aa bb))
      vm2.update!(:retired => true)

      get api_vms_url, :params => { :expand => "resources", :filter => ["retired!=nil"] }

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm2.name, "guid" => vm2.guid}])
    end

    it "supports numerical less than comparison via <" do
      vm1, vm2, vm3 = create_vms_by_name(%w(aa bb cc))

      get api_vms_url, :params => { :expand => "resources", :filter => ["id < #{vm3.id}"], :sort_by => "name" }

      expect_query_result(:vms, 2, 3)
      expect_result_resources_to_match_hash([{"name" => vm1.name, "guid" => vm1.guid},
                                             {"name" => vm2.name, "guid" => vm2.guid}])
    end

    it "supports numerical less than or equal comparison via <=" do
      vm1, vm2, _vm3 = create_vms_by_name(%w(aa bb cc))

      get api_vms_url, :params => { :expand => "resources", :filter => ["id <= #{vm2.id}"], :sort_by => "name" }

      expect_query_result(:vms, 2, 3)
      expect_result_resources_to_match_hash([{"name" => vm1.name, "guid" => vm1.guid},
                                             {"name" => vm2.name, "guid" => vm2.guid}])
    end

    it "support greater than numerical comparison via >" do
      vm1, vm2 = create_vms_by_name(%w(aa bb))

      get api_vms_url, :params => { :expand => "resources", :filter => ["id > #{vm1.id}"], :sort_by => "name" }

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm2.name, "guid" => vm2.guid}])
    end

    it "supports greater or equal than numerical comparison via >=" do
      _vm1, vm2, vm3 = create_vms_by_name(%w(aa bb cc))

      get api_vms_url, :params => { :expand => "resources", :filter => ["id >= #{vm2.id}"], :sort_by => "name" }

      expect_query_result(:vms, 2, 3)
      expect_result_resources_to_match_hash([{"name" => vm2.name, "guid" => vm2.guid},
                                             {"name" => vm3.name, "guid" => vm3.guid}])
    end

    it "supports compound logical OR comparisons" do
      vm1, vm2, vm3 = create_vms_by_name(%w(aa bb cc))

      get(
        api_vms_url,
        :params => {
          :expand  => "resources",
          :filter  => ["id = #{vm1.id}", "or id > #{vm2.id}"],
          :sort_by => "name"
        }
      )

      expect_query_result(:vms, 2, 3)
      expect_result_resources_to_match_hash([{"name" => vm1.name, "guid" => vm1.guid},
                                             {"name" => vm3.name, "guid" => vm3.guid}])
    end

    it "supports multiple logical AND comparisons" do
      vm1, _vm2 = create_vms_by_name(%w(aa bb))

      get(
        api_vms_url,
        :params => {
          :expand => "resources",
          :filter => ["id = #{vm1.id}", "name = #{vm1.name}"]
        }
      )

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm1.name, "guid" => vm1.guid}])
    end

    it "supports multiple comparisons with both AND and OR" do
      vm1, vm2, vm3 = create_vms_by_name(%w(aa bb cc))

      get(
        api_vms_url,
        :params => {
          :expand  => "resources",
          :filter  => ["id = #{vm1.id}", "name = #{vm1.name}", "or id > #{vm2.id}"],
          :sort_by => "name"
        }
      )

      expect_query_result(:vms, 2, 3)
      expect_result_resources_to_match_hash([{"name" => vm1.name, "guid" => vm1.guid},
                                             {"name" => vm3.name, "guid" => vm3.guid}])
    end

    it "supports filtering by attributes of associations" do
      host1 = FactoryBot.create(:host, :name => "foo")
      host2 = FactoryBot.create(:host, :name => "bar")
      vm1 = FactoryBot.create(:vm_vmware, :name => "baz", :host => host1)
      _vm2 = FactoryBot.create(:vm_vmware, :name => "qux", :host => host2)

      get(
        api_vms_url,
        :params => {
          :expand => "resources",
          :filter => ["host.name='foo'"]
        }
      )

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm1.name, "guid" => vm1.guid}])
    end

    it "supports filtering by attributes of associations with paging" do
      host1 = FactoryBot.create(:host, :name => "foo")
      host2 = FactoryBot.create(:host, :name => "bar")
      vm1 = FactoryBot.create(:vm_vmware, :name => "baz", :host => host1)
      _vm2 = FactoryBot.create(:vm_vmware, :name => "qux", :host => host2)

      get(
        api_vms_url,
        :params => {
          :expand => "resources",
          :filter => ["host.name='foo'"],
          :offset => 0,
          :limit  => 1
        }
      )

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm1.name, "guid" => vm1.guid}])
    end

    it "does not support filtering by attributes of associations' associations" do
      get api_vms_url, :params => { :expand => "resources", :filter => ["host.hardware.memory_mb>1024"] }

      expect_bad_request(/Filtering of attributes with more than one association away is not supported/)
    end

    it "supports filtering by virtual string attributes" do
      host_a = FactoryBot.create(:host, :name => "aa")
      host_b = FactoryBot.create(:host, :name => "bb")
      vm_a = FactoryBot.create(:vm, :host => host_a)
      _vm_b = FactoryBot.create(:vm, :host => host_b)

      get(api_vms_url, :params => { :filter => ["host_name='aa'"], :expand => "resources" })

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm_a.name, "guid" => vm_a.guid}])
    end

    it "supports flexible filtering by virtual string attributes" do
      host_a = FactoryBot.create(:host, :name => "ab")
      host_b = FactoryBot.create(:host, :name => "cd")
      vm_a = FactoryBot.create(:vm, :host => host_a)
      _vm_b = FactoryBot.create(:vm, :host => host_b)

      get(api_vms_url, :params => { :filter => ["host_name='a%'"], :expand => "resources" })

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm_a.name, "guid" => vm_a.guid}])
    end

    it "supports filtering by virtual boolean attributes" do
      ems = FactoryBot.create(:ext_management_system)
      storage = FactoryBot.create(:storage)
      host = FactoryBot.create(:host, :storages => [storage])
      _vm = FactoryBot.create(:vm, :host => host, :ext_management_system => ems)
      archived_vm = FactoryBot.create(:vm)

      get(api_vms_url, :params => { :filter => ["archived=true"], :expand => "resources" })

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => archived_vm.name, "guid" => archived_vm.guid}])
    end

    it "supports filtering by comparison of virtual integer attributes" do
      hardware_1 = FactoryBot.create(:hardware, :cpu_sockets => 4)
      hardware_2 = FactoryBot.create(:hardware, :cpu_sockets => 8)
      _vm_1 = FactoryBot.create(:vm, :hardware => hardware_1)
      vm_2 = FactoryBot.create(:vm, :hardware => hardware_2)

      get(api_vms_url, :params => { :filter => ["num_cpu > 4"], :expand => "resources" })

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm_2.name, "guid" => vm_2.guid}])
    end

    it "supports = with dates mixed with virtual attributes" do
      _vm_1 = FactoryBot.create(:vm, :retires_on => "2016-01-01", :vendor => "vmware")
      vm_2 = FactoryBot.create(:vm, :retires_on => "2016-01-02", :vendor => "vmware")
      _vm_3 = FactoryBot.create(:vm, :retires_on => "2016-01-02", :vendor => "openstack")

      get(api_vms_url, :params => { :filter => ["retires_on = 2016-01-02", "vendor_display = VMware"] })

      expected = {"resources" => [{"href" => api_vm_url(nil, vm_2)}]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports > with dates mixed with virtual attributes" do
      _vm_1 = FactoryBot.create(:vm, :retires_on => "2016-01-01", :vendor => "vmware")
      vm_2 = FactoryBot.create(:vm, :retires_on => "2016-01-02", :vendor => "vmware")
      _vm_3 = FactoryBot.create(:vm, :retires_on => "2016-01-03", :vendor => "openstack")

      get(api_vms_url, :params => { :filter => ["retires_on > 2016-01-01", "vendor_display = VMware"] })

      expected = {"resources" => [{"href" => api_vm_url(nil, vm_2)}]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports > with datetimes mixed with virtual attributes" do
      _vm_1 = FactoryBot.create(:vm, :last_scan_on => "2016-01-01T07:59:59Z", :vendor => "vmware")
      vm_2 = FactoryBot.create(:vm, :last_scan_on => "2016-01-01T08:00:00Z", :vendor => "vmware")
      _vm_3 = FactoryBot.create(:vm, :last_scan_on => "2016-01-01T08:00:00Z", :vendor => "openstack")

      get(api_vms_url, :params => { :filter => ["last_scan_on > 2016-01-01T07:59:59Z", "vendor_display = VMware"] })

      expected = {"resources" => [{"href" => api_vm_url(nil, vm_2)}]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports < with dates mixed with virtual attributes" do
      _vm_1 = FactoryBot.create(:vm, :retires_on => "2016-01-01", :vendor => "openstack")
      vm_2 = FactoryBot.create(:vm, :retires_on => "2016-01-02", :vendor => "vmware")
      _vm_3 = FactoryBot.create(:vm, :retires_on => "2016-01-03", :vendor => "vmware")

      get(api_vms_url, :params => { :filter => ["retires_on < 2016-01-03", "vendor_display = VMware"] })

      expected = {"resources" => [{"href" => api_vm_url(nil, vm_2)}]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports < with datetimes mixed with virtual attributes" do
      _vm_1 = FactoryBot.create(:vm, :last_scan_on => "2016-01-01T07:59:59Z", :vendor => "openstack")
      vm_2 = FactoryBot.create(:vm, :last_scan_on => "2016-01-01T07:59:59Z", :vendor => "vmware")
      _vm_3 = FactoryBot.create(:vm, :last_scan_on => "2016-01-01T08:00:00Z", :vendor => "vmware")

      get(api_vms_url, :params => { :filter => ["last_scan_on < 2016-01-01T08:00:00Z", "vendor_display = VMware"] })

      expected = {"resources" => [{"href" => api_vm_url(nil, vm_2)}]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "does not support filtering with <= with datetimes" do
      get(api_vms_url, :params => { :filter => ["retires_on <= 2016-01-03"] })

      expect(response.parsed_body).to include_error_with_message("Unsupported operator for datetime: <=")
      expect(response).to have_http_status(:bad_request)
    end

    it "does not support filtering with >= with datetimes" do
      get(api_vms_url, :params => { :filter => ["retires_on >= 2016-01-03"] })

      expect(response.parsed_body).to include_error_with_message("Unsupported operator for datetime: >=")
      expect(response).to have_http_status(:bad_request)
    end

    it "does not support filtering with != with datetimes" do
      get(api_vms_url, :params => { :filter => ["retires_on != 2016-01-03"] })

      expect(response.parsed_body).to include_error_with_message("Unsupported operator for datetime: !=")
      expect(response).to have_http_status(:bad_request)
    end

    it "will handle poorly formed datetimes in the filter" do
      get(api_vms_url, :params => { :filter => ["retires_on > foobar"] })

      expect(response.parsed_body).to include_error_with_message("Bad format for datetime: foobar")
      expect(response).to have_http_status(:bad_request)
    end

    it "does not support filtering vms as a subcollection" do
      service = FactoryBot.create(:service)
      service << FactoryBot.create(:vm_vmware, :name => "foo")
      service << FactoryBot.create(:vm_vmware, :name => "bar")

      get(api_service_vms_url(nil, service), :params => { :filter => ["name=foo"] })

      expect(response.parsed_body).to include_error_with_message("Filtering is not supported on vms subcollection")
      expect(response).to have_http_status(:bad_request)
    end

    it "can do fuzzy matching on strings with forward slashes" do
      tag_1 = FactoryBot.create(:classification, :name => "foo").tag
      _tag_2 = FactoryBot.create(:classification, :name => "bar")
      api_basic_authorize collection_action_identifier(:tags, :read, :get)

      get(api_tags_url, :params => { :filter => ["name='*/foo'"] })

      expected = {
        "count"     => 2,
        "subcount"  => 1,
        "resources" => [{"href" => api_tag_url(nil, tag_1)}]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "returns a bad request if trying to filter on invalid attributes" do
      get(api_vms_url, :params => { :filter => ["destroy=true"] })

      expected = {
        "error" => a_hash_including(
          "kind"    => "bad_request",
          "message" => /attribute Vm-destroy does not exist/
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "Querying vm attributes" do
    it "supports requests specific attributes" do
      api_basic_authorize collection_action_identifier(:vms, :read, :get)
      vm = create_vms_by_name(%w(aa)).first

      get api_vms_url, :params => { :expand => "resources", :attributes => "href_slug,name,vendor" }

      expected = {
        "name"      => "vms",
        "count"     => 1,
        "subcount"  => 1,
        "resources" => [
          {
            "id"        => vm.id.to_s,
            "href"      => api_vm_url(nil, vm),
            "href_slug" => "vms/#{vm.id}",
            "name"      => "aa",
            "vendor"    => anything
          }
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Querying vms by tag" do
    it "is supported" do
      api_basic_authorize collection_action_identifier(:vms, :read, :get)
      vm1, _vm2, vm3 = create_vms_by_name(%w(aa bb cc))

      dept = FactoryBot.create(:classification_department)
      FactoryBot.create(:classification_tag, :name => "finance", :description => "Finance", :parent => dept)
      Classification.classify(vm1, "department", "finance")
      Classification.classify(vm3, "department", "finance")

      get api_vms_url, :params => { :expand => "resources", :by_tag => "/department/finance" }

      expect_query_result(:vms, 2, 3)
      expect_result_resources_to_include_data("resources", "name" => [vm1.name, vm3.name])
    end

    it "supports multiple comma separated tags" do
      api_basic_authorize collection_action_identifier(:vms, :read, :get)
      vm1, _vm2, vm3 = create_vms_by_name(%w(aa bb cc))

      dept = FactoryBot.create(:classification_department)
      cc = FactoryBot.create(:classification_cost_center)
      FactoryBot.create(:classification_tag, :name => "finance", :description => "Finance", :parent => dept)
      FactoryBot.create(:classification_tag, :name => "cc01", :description => "Cost Center 1", :parent => cc)

      Classification.classify(vm1, "department", "finance")
      Classification.classify(vm1, "cc", "cc01")
      Classification.classify(vm3, "department", "finance")

      get api_vms_url, :params => { :expand => "resources", :by_tag => "/department/finance,/cc/cc01" }

      expect_query_result(:vms, 1, 3)
      expect_result_resources_to_include_data("resources", "name" => [vm1.name])
    end
  end

  describe "Querying vms" do
    before { api_basic_authorize collection_action_identifier(:vms, :read, :get) }

    it "and sorted by name succeeeds with unreferenced class" do
      get api_vms_url, :params => { :sort_by => "name", :expand => "resources" }

      expect_query_result(:vms, 0, 0)
    end

    it "by invalid attribute" do
      get api_vms_url, :params => { :sort_by => "bad_attribute", :expand => "resources" }

      expect_bad_request("bad_attribute is not a valid attribute")
    end

    it "is supported without expanding resources" do
      create_vms_by_name(%w(aa bb))

      get api_vms_url

      expected = {
        "name"      => "vms",
        "count"     => 2,
        "subcount"  => 2,
        "resources" => Array.new(2) { {"href" => anything} }
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports expanding resources" do
      create_vms_by_name(%w(aa bb))

      get api_vms_url, :params => { :expand => "resources" }

      expect_query_result(:vms, 2, 2)
      expect_result_resources_to_include_keys("resources", %w(id href guid name vendor))
    end

    it "supports expanding resources and subcollections" do
      vm1 = create_vms_by_name(%w(aa)).first
      FactoryBot.create(:guest_application, :vm_or_template_id => vm1.id, :name => "LibreOffice")

      get api_vms_url, :params => { :expand => "resources,software" }

      expect_query_result(:vms, 1, 1)
      expect_result_resources_to_include_keys("resources", %w(id href guid name vendor software))
    end

    it "supports suppressing resources" do
      FactoryBot.create(:vm)

      get(api_vms_url, :params => { :hide => "resources" })

      expect(response.parsed_body).not_to include("resources")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Querying resources" do
    it "does not return actions if not entitled" do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)

      get api_vm_url(nil, vm1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to_not have_key("actions")
    end

    it "returns actions if authorized" do
      api_basic_authorize action_identifier(:vms, :edit), action_identifier(:vms, :read, :resource_actions, :get)

      get api_vm_url(nil, vm1)

      expect(response).to have_http_status(:ok)
      expect_result_to_have_keys(%w(id href name vendor actions))
    end

    it "returns correct actions if authorized as such" do
      api_basic_authorize action_identifier(:vms, :suspend), action_identifier(:vms, :read, :resource_actions, :get)

      get api_vm_url(nil, vm1)

      expect(response).to have_http_status(:ok)
      expect_result_to_have_keys(%w(id href name vendor actions))
      actions = response.parsed_body["actions"]
      expect(actions.size).to eq(1)
      expect(actions.first["name"]).to eq("suspend")
    end

    it 'returns correct actions on a collection' do
      api_basic_authorize(collection_action_identifier(:vms, :read, :get),
                          action_identifier(:vms, :start),
                          action_identifier(:vms, :stop))

      get(api_vms_url)

      actions = response.parsed_body['actions']
      expect(actions.size).to eq(3)
      expect(actions.collect { |a| a['name'] }).to match_array(%w(start stop query))
      expect_result_to_have_keys(%w(name count subcount resources actions))
    end

    it 'returns correct actions on a subcollection' do
      api_basic_authorize subcollection_action_identifier(:vms, :snapshots, :read, :get),
                          subcollection_action_identifier(:vms, :snapshots, :delete, :post),
                          subcollection_action_identifier(:vms, :snapshots, :create, :post)
      vm = FactoryBot.create(:vm)
      FactoryBot.create(:snapshot, :vm_or_template => vm)

      get(api_vm_snapshots_url(nil, vm))

      actions = response.parsed_body['actions']
      expect(actions.size).to eq(2)
      expect(actions.collect { |a| a['name'] }).to match_array(%w(create delete))
      expect_result_to_have_keys(%w(name count subcount resources actions))
    end

    it 'returns the correct actions on a subresource' do
      api_basic_authorize subcollection_action_identifier(:vms, :snapshots, :delete, :post),
                          subcollection_action_identifier(:vms, :snapshots, :read, :get),
                          subcollection_action_identifier(:vms, :snapshots, :create, :post)

      vm = FactoryBot.create(:vm)
      snapshot = FactoryBot.create(:snapshot, :vm_or_template => vm)

      get(api_vm_snapshot_url(nil, vm, snapshot))

      actions = response.parsed_body['actions']
      expect(actions.collect { |a| a['name'] }).to match_array(%w[delete])
      expect_result_to_have_keys(%w(href id actions))
    end

    it "returns multiple actions if authorized as such" do
      api_basic_authorize(action_identifier(:vms, :start),
                          action_identifier(:vms, :stop),
                          action_identifier(:vms, :read, :resource_actions, :get))

      get api_vm_url(nil, vm1)

      expect(response).to have_http_status(:ok)
      expect_result_to_have_keys(%w(id href name vendor actions))
      expect(response.parsed_body["actions"].collect { |a| a["name"] }).to match_array(%w(start stop))
    end

    it "returns actions if asked for with physical attributes" do
      api_basic_authorize action_identifier(:vms, :start), action_identifier(:vms, :read, :resource_actions, :get)

      get api_vm_url(nil, vm1), :params => { :attributes => "name,vendor,actions" }

      expect(response).to have_http_status(:ok)
      expect_result_to_have_only_keys(%w(id href name vendor actions))
    end

    it "does not return actions if asking for a physical attribute" do
      api_basic_authorize action_identifier(:vms, :start), action_identifier(:vms, :read, :resource_actions, :get)

      get api_vm_url(nil, vm1), :params => { :attributes => "name" }

      expect(response).to have_http_status(:ok)
      expect_result_to_have_only_keys(%w(id href name))
    end

    it "does return actions if asking for virtual attributes" do
      api_basic_authorize action_identifier(:vms, :start), action_identifier(:vms, :read, :resource_actions, :get)

      get api_vm_url(nil, vm1), :params => { :attributes => "disconnected" }

      expect(response).to have_http_status(:ok)
      expect_result_to_have_keys(%w(id href name vendor disconnected actions))
    end

    it "does not return actions if asking for physical and virtual attributes" do
      api_basic_authorize action_identifier(:vms, :start), action_identifier(:vms, :read, :resource_actions, :get)

      get api_vm_url(nil, vm1), :params => { :attributes => "name,disconnected" }

      expect(response).to have_http_status(:ok)
      expect_result_to_have_only_keys(%w(id href name disconnected))
    end
  end

  describe 'OPTIONS /api/vms' do
    it 'returns the options information' do
      options(api_vms_url)
      expect_options_results(:vms, {})
    end
  end

  describe "with optional collection_class" do
    before { api_basic_authorize collection_action_identifier(:vms, :read, :get) }

    it "fail with invalid collection_class specified" do
      get api_vms_url, :params => { :collection_class => "BogusClass" }

      expect_bad_request("Invalid collection_class BogusClass specified for the vms collection")
    end

    it "succeed with collection_class matching the collection class" do
      create_vms_by_name(%w(aa bb))

      get api_vms_url, :params => { :collection_class => "Vm" }

      expect_query_result(:vms, 2, 2)
    end

    it "succeed with collection_class matching the collection class and returns subclassed resources" do
      FactoryBot.create(:vm_vmware, :name => "aa")
      FactoryBot.create(:vm_vmware_cloud, :name => "bb")
      FactoryBot.create(:vm_vmware_cloud, :name => "cc")

      get api_vms_url, :params => { :expand => "resources", :collection_class => "Vm" }

      expect_query_result(:vms, 3, 3)
      expect(response.parsed_body["resources"].collect { |vm| vm["name"] }).to match_array(%w(aa bb cc))
    end

    it "succeed with collection_class and only returns subclassed resources" do
      FactoryBot.create(:vm_vmware, :name => "aa")
      FactoryBot.create(:vm_vmware_cloud, :name => "bb")
      vmcc = FactoryBot.create(:vm_vmware_cloud, :name => "cc")

      get api_vms_url, :params => { :expand => "resources", :collection_class => vmcc.class.name }

      expect_query_result(:vms, 2, 2)
      expect(response.parsed_body["resources"].collect { |vm| vm["name"] }).to match_array(%w(bb cc))
    end

    it "finds child classes given a parent class" do
      FactoryBot.create(:vm_vmware, :name => "aa")
      FactoryBot.create(:vm_vmware_cloud, :name => "bb")
      FactoryBot.create(:vm_amazon, :name => "cc")

      # parent of amazon and vmware_cloud.
      vmc = FactoryBot.build(:vm_cloud)

      get api_vms_url, :params => { :expand => "resources", :collection_class => vmc.class.name }

      expect_query_result(:vms, 2, 2)
      expect(response.parsed_body["resources"].collect { |vm| vm["name"] }).to match_array(%w(bb cc))
    end
  end
end
