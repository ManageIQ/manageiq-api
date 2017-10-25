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
    names.each.collect { |name| FactoryGirl.create(:vm_vmware, :name => name) }
  end

  let(:vm1) { FactoryGirl.create(:vm_vmware, :name => "vm1") }

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
      FactoryGirl.create_list(:vm, 3)

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
      vm = FactoryGirl.create(:vm)

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

    it "supports ascending order" do
      create_vms_by_name %w(cc aa bb)

      get api_vms_url, :params => { :sort_by => "name", :sort_order => "asc", :expand => "resources" }

      expect_query_result(:vms, 3, 3)
      expect_result_resources_to_match_hash([{"name" => "aa"}, {"name" => "bb"}, {"name" => "cc"}])
    end

    it "supports decending order" do
      create_vms_by_name %w(cc aa bb)

      get api_vms_url, :params => { :sort_by => "name", :sort_order => "desc", :expand => "resources" }

      expect_query_result(:vms, 3, 3)
      expect_result_resources_to_match_hash([{"name" => "cc"}, {"name" => "bb"}, {"name" => "aa"}])
    end

    it "supports case insensitive ordering" do
      create_vms_by_name %w(B c a)

      get api_vms_url, :params => { :sort_by => "name", :sort_order => "asc", :sort_options => "ignore_case", :expand => "resources" }

      expect_query_result(:vms, 3, 3)
      expect_result_resources_to_match_hash([{"name" => "a"}, {"name" => "B"}, {"name" => "c"}])
    end

    it "supports sorting with physical attributes" do
      FactoryGirl.create(:vm_vmware, :vendor => "vmware", :name => "vmware_vm")
      FactoryGirl.create(:vm_redhat, :vendor => "redhat", :name => "redhat_vm")

      get api_vms_url, :params => { :sort_by => "vendor", :sort_order => "asc", :expand => "resources" }

      expect_query_result(:vms, 2, 2)
      expect_result_resources_to_match_hash([{"name" => "redhat_vm"}, {"name" => "vmware_vm"}])
    end

    it 'supports sql friendly virtual attributes' do
      host_foo =  FactoryGirl.create(:host, :name => 'foo')
      host_bar =  FactoryGirl.create(:host, :name => 'bar')
      host_zap =  FactoryGirl.create(:host, :name => 'zap')
      FactoryGirl.create(:vm, :name => 'vm_foo', :host => host_foo)
      FactoryGirl.create(:vm, :name => 'vm_bar', :host => host_bar)
      FactoryGirl.create(:vm, :name => 'vm_zap', :host => host_zap)

      get api_vms_url, :params => { :sort_by => 'host_name', :sort_order => 'desc', :expand => 'resources' }

      expect_query_result(:vms, 3, 3)
      expect_result_resources_to_match_hash([{'name' => 'vm_zap'}, {'name' => 'vm_foo'}, {'name' => 'vm_bar'}])
    end

    it 'does not support non sql friendly virtual attributes' do
      FactoryGirl.create(:vm)

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
      svc1, _svc2 = FactoryGirl.create_list(:service, 2)
      dept = FactoryGirl.create(:classification_department)
      FactoryGirl.create(:classification_tag, :name => 'finance', :parent => dept)
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
      vm2.update_attributes!(:retired => true)

      get api_vms_url, :params => { :expand => "resources", :filter => ["retired=NULL"] }

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm1.name, "guid" => vm1.guid}])
    end

    it "supports NULL/nil inequality test via !=" do
      _vm1, vm2 = create_vms_by_name(%w(aa bb))
      vm2.update_attributes!(:retired => true)

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
      host1 = FactoryGirl.create(:host, :name => "foo")
      host2 = FactoryGirl.create(:host, :name => "bar")
      vm1 = FactoryGirl.create(:vm_vmware, :name => "baz", :host => host1)
      _vm2 = FactoryGirl.create(:vm_vmware, :name => "qux", :host => host2)

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
      host1 = FactoryGirl.create(:host, :name => "foo")
      host2 = FactoryGirl.create(:host, :name => "bar")
      vm1 = FactoryGirl.create(:vm_vmware, :name => "baz", :host => host1)
      _vm2 = FactoryGirl.create(:vm_vmware, :name => "qux", :host => host2)

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
      host_a = FactoryGirl.create(:host, :name => "aa")
      host_b = FactoryGirl.create(:host, :name => "bb")
      vm_a = FactoryGirl.create(:vm, :host => host_a)
      _vm_b = FactoryGirl.create(:vm, :host => host_b)

      get(api_vms_url, :params => { :filter => ["host_name='aa'"], :expand => "resources" })

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm_a.name, "guid" => vm_a.guid}])
    end

    it "supports flexible filtering by virtual string attributes" do
      host_a = FactoryGirl.create(:host, :name => "ab")
      host_b = FactoryGirl.create(:host, :name => "cd")
      vm_a = FactoryGirl.create(:vm, :host => host_a)
      _vm_b = FactoryGirl.create(:vm, :host => host_b)

      get(api_vms_url, :params => { :filter => ["host_name='a%'"], :expand => "resources" })

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm_a.name, "guid" => vm_a.guid}])
    end

    it "supports filtering by virtual boolean attributes" do
      ems = FactoryGirl.create(:ext_management_system)
      storage = FactoryGirl.create(:storage)
      host = FactoryGirl.create(:host, :storages => [storage])
      _vm = FactoryGirl.create(:vm, :host => host, :ext_management_system => ems)
      archived_vm = FactoryGirl.create(:vm)

      get(api_vms_url, :params => { :filter => ["archived=true"], :expand => "resources" })

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => archived_vm.name, "guid" => archived_vm.guid}])
    end

    it "supports filtering by comparison of virtual integer attributes" do
      hardware_1 = FactoryGirl.create(:hardware, :cpu_sockets => 4)
      hardware_2 = FactoryGirl.create(:hardware, :cpu_sockets => 8)
      _vm_1 = FactoryGirl.create(:vm, :hardware => hardware_1)
      vm_2 = FactoryGirl.create(:vm, :hardware => hardware_2)

      get(api_vms_url, :params => { :filter => ["num_cpu > 4"], :expand => "resources" })

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm_2.name, "guid" => vm_2.guid}])
    end

    it "supports = with dates mixed with virtual attributes" do
      _vm_1 = FactoryGirl.create(:vm, :retires_on => "2016-01-01", :vendor => "vmware")
      vm_2 = FactoryGirl.create(:vm, :retires_on => "2016-01-02", :vendor => "vmware")
      _vm_3 = FactoryGirl.create(:vm, :retires_on => "2016-01-02", :vendor => "openstack")

      get(api_vms_url, :params => { :filter => ["retires_on = 2016-01-02", "vendor_display = VMware"] })

      expected = {"resources" => [{"href" => api_vm_url(nil, vm_2)}]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports > with dates mixed with virtual attributes" do
      _vm_1 = FactoryGirl.create(:vm, :retires_on => "2016-01-01", :vendor => "vmware")
      vm_2 = FactoryGirl.create(:vm, :retires_on => "2016-01-02", :vendor => "vmware")
      _vm_3 = FactoryGirl.create(:vm, :retires_on => "2016-01-03", :vendor => "openstack")

      get(api_vms_url, :params => { :filter => ["retires_on > 2016-01-01", "vendor_display = VMware"] })

      expected = {"resources" => [{"href" => api_vm_url(nil, vm_2)}]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports > with datetimes mixed with virtual attributes" do
      _vm_1 = FactoryGirl.create(:vm, :last_scan_on => "2016-01-01T07:59:59Z", :vendor => "vmware")
      vm_2 = FactoryGirl.create(:vm, :last_scan_on => "2016-01-01T08:00:00Z", :vendor => "vmware")
      _vm_3 = FactoryGirl.create(:vm, :last_scan_on => "2016-01-01T08:00:00Z", :vendor => "openstack")

      get(api_vms_url, :params => { :filter => ["last_scan_on > 2016-01-01T07:59:59Z", "vendor_display = VMware"] })

      expected = {"resources" => [{"href" => api_vm_url(nil, vm_2)}]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports < with dates mixed with virtual attributes" do
      _vm_1 = FactoryGirl.create(:vm, :retires_on => "2016-01-01", :vendor => "openstack")
      vm_2 = FactoryGirl.create(:vm, :retires_on => "2016-01-02", :vendor => "vmware")
      _vm_3 = FactoryGirl.create(:vm, :retires_on => "2016-01-03", :vendor => "vmware")

      get(api_vms_url, :params => { :filter => ["retires_on < 2016-01-03", "vendor_display = VMware"] })

      expected = {"resources" => [{"href" => api_vm_url(nil, vm_2)}]}
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports < with datetimes mixed with virtual attributes" do
      _vm_1 = FactoryGirl.create(:vm, :last_scan_on => "2016-01-01T07:59:59Z", :vendor => "openstack")
      vm_2 = FactoryGirl.create(:vm, :last_scan_on => "2016-01-01T07:59:59Z", :vendor => "vmware")
      _vm_3 = FactoryGirl.create(:vm, :last_scan_on => "2016-01-01T08:00:00Z", :vendor => "vmware")

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
      service = FactoryGirl.create(:service)
      service << FactoryGirl.create(:vm_vmware, :name => "foo")
      service << FactoryGirl.create(:vm_vmware, :name => "bar")

      get(api_service_vms_url(nil, service), :params => { :filter => ["name=foo"] })

      expect(response.parsed_body).to include_error_with_message("Filtering is not supported on vms subcollection")
      expect(response).to have_http_status(:bad_request)
    end

    it "can do fuzzy matching on strings with forward slashes" do
      tag_1 = FactoryGirl.create(:tag, :name => "/managed/foo")
      _tag_2 = FactoryGirl.create(:tag, :name => "/managed/bar")
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

    it "supports filtering by compressed id" do
      vm1, _vm2 = create_vms_by_name(%w(aa bb))

      get(
        api_vms_url,
        :params => {
          :expand => "resources",
          :filter => ["id = #{ApplicationRecord.compress_id(vm1.id)}"]
        }
      )

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm1.name, "guid" => vm1.guid}])
    end

    it "supports filtering by compressed id as string" do
      _vm1, vm2 = create_vms_by_name(%w(aa bb))

      get(
        api_vms_url,
        :params => {
          :expand => "resources",
          :filter => ["id = '#{ApplicationRecord.compress_id(vm2.id)}'"]
        }
      )

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm2.name, "guid" => vm2.guid}])
    end

    it "supports filtering by compressed id on *_id named attributes" do
      zone = FactoryGirl.create(:zone, :name => "api_zone")
      ems1 = FactoryGirl.create(:ems_vmware, :zone => zone)
      ems2 = FactoryGirl.create(:ems_vmware, :zone => zone)
      host = FactoryGirl.create(:host)

      _vm = FactoryGirl.create(:vm_vmware,
                               :host                  => host,
                               :ext_management_system => ems1,
                               :raw_power_state       => "poweredOn")
      vm2 = FactoryGirl.create(:vm_vmware,
                               :host                  => host,
                               :ext_management_system => ems2,
                               :raw_power_state       => "poweredOff")

      get(
        api_vms_url,
        :params => {
          :expand => "resources",
          :filter => ["ems_id = #{ApplicationRecord.compress_id(ems2.id)}"]
        }
      )

      expect_query_result(:vms, 1, 2)
      expect_result_resources_to_match_hash([{"name" => vm2.name, "guid" => vm2.guid}])
    end

    it "returns a bad request if trying to filter on invalid attributes" do
      get(api_vms_url, :params => { :filter => ["destroy=true"] })

      expected = {
        "error" => a_hash_including(
          "kind"    => "bad_request",
          "message" => "Must filter on valid attributes for resource"
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

      dept = FactoryGirl.create(:classification_department)
      FactoryGirl.create(:classification_tag, :name => "finance", :description => "Finance", :parent => dept)
      Classification.classify(vm1, "department", "finance")
      Classification.classify(vm3, "department", "finance")

      get api_vms_url, :params => { :expand => "resources", :by_tag => "/department/finance" }

      expect_query_result(:vms, 2, 3)
      expect_result_resources_to_include_data("resources", "name" => [vm1.name, vm3.name])
    end

    it "supports multiple comma separated tags" do
      api_basic_authorize collection_action_identifier(:vms, :read, :get)
      vm1, _vm2, vm3 = create_vms_by_name(%w(aa bb cc))

      dept = FactoryGirl.create(:classification_department)
      cc = FactoryGirl.create(:classification_cost_center)
      FactoryGirl.create(:classification_tag, :name => "finance", :description => "Finance", :parent => dept)
      FactoryGirl.create(:classification_tag, :name => "cc01", :description => "Cost Center 1", :parent => cc)

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
      FactoryGirl.create(:guest_application, :vm_or_template_id => vm1.id, :name => "LibreOffice")

      get api_vms_url, :params => { :expand => "resources,software" }

      expect_query_result(:vms, 1, 1)
      expect_result_resources_to_include_keys("resources", %w(id href guid name vendor software))
    end

    it "supports suppressing resources" do
      FactoryGirl.create(:vm)

      get(api_vms_url, :params => { :hide => "resources" })

      expect(response.parsed_body).not_to include("resources")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Querying resources" do
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
      expect_options_results(:vms)
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
      FactoryGirl.create(:vm_vmware, :name => "aa")
      FactoryGirl.create(:vm_vmware_cloud, :name => "bb")
      FactoryGirl.create(:vm_vmware_cloud, :name => "cc")

      get api_vms_url, :params => { :expand => "resources", :collection_class => "Vm" }

      expect_query_result(:vms, 3, 3)
      expect(response.parsed_body["resources"].collect { |vm| vm["name"] }).to match_array(%w(aa bb cc))
    end

    it "succeed with collection_class and only returns subclassed resources" do
      FactoryGirl.create(:vm_vmware, :name => "aa")
      FactoryGirl.create(:vm_vmware_cloud, :name => "bb")
      vmcc = FactoryGirl.create(:vm_vmware_cloud, :name => "cc")

      get api_vms_url, :params => { :expand => "resources", :collection_class => vmcc.class.name }

      expect_query_result(:vms, 2, 2)
      expect(response.parsed_body["resources"].collect { |vm| vm["name"] }).to match_array(%w(bb cc))
    end
  end
end
