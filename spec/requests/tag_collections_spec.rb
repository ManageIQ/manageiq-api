#
# REST API Request Tests - Tags subcollection specs for Non-Vm collections
#
describe "Tag Collections API" do
  let(:zone)         { FactoryGirl.create(:zone, :name => "api_zone") }
  let(:ems)          { FactoryGirl.create(:ems_vmware, :zone => zone) }
  let(:host)         { FactoryGirl.create(:host) }

  let(:tag1)         { {:category => "department", :name => "finance", :path => "/managed/department/finance"} }
  let(:tag2)         { {:category => "cc",         :name => "001",     :path => "/managed/cc/001"} }
  let(:tag_paths)    { [tag1[:path], tag2[:path]] }

  def classify_resource(resource)
    Classification.classify(resource, tag1[:category], tag1[:name])
    Classification.classify(resource, tag2[:category], tag2[:name])
  end

  def tag1_results(resource_href)
    [{:success => true, :href => resource_href, :tag_category => tag1[:category], :tag_name => tag1[:name]}]
  end

  def expect_resource_has_tags(resource, tag_names)
    tag_names = Array.wrap(tag_names)
    expect(resource.tags.count).to eq(tag_names.count)
    expect(resource.tags.map(&:name).sort).to eq(tag_names.sort)
  end

  before do
    FactoryGirl.create(:classification_department_with_tags)
    FactoryGirl.create(:classification_cost_center_with_tags)
  end

  context "Provider Tag subcollection" do
    let(:provider)          { ems }

    it "query all tags of a Provider and verify tag category and names" do
      api_basic_authorize
      classify_resource(provider)

      get api_provider_tags_url(nil, provider), :expand => "resources"

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Provider without appropriate role" do
      api_basic_authorize

      post(api_provider_tags_url(nil, provider), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Provider" do
      api_basic_authorize subcollection_action_identifier(:providers, :tags, :assign)

      post(api_provider_tags_url(nil, provider), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_provider_url(nil, provider.compressed_id)))
    end

    it "does not unassign a tag from a Provider without appropriate role" do
      api_basic_authorize

      post(api_provider_tags_url(nil, provider), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Provider" do
      api_basic_authorize subcollection_action_identifier(:providers, :tags, :unassign)
      classify_resource(provider)

      post(api_provider_tags_url(nil, provider), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_provider_url(nil, provider.compressed_id)))
      expect_resource_has_tags(provider, tag2[:path])
    end
  end

  context "Host Tag subcollection" do
    it "query all tags of a Host and verify tag category and names" do
      api_basic_authorize
      classify_resource(host)

      get api_host_tags_url(nil, host), :expand => "resources"

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Host without appropriate role" do
      api_basic_authorize

      post(api_host_tags_url(nil, host), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Host" do
      api_basic_authorize subcollection_action_identifier(:hosts, :tags, :assign)

      post(api_host_tags_url(nil, host), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_host_url(nil, host.compressed_id)))
    end

    it "does not unassign a tag from a Host without appropriate role" do
      api_basic_authorize

      post(api_host_tags_url(nil, host), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Host" do
      api_basic_authorize subcollection_action_identifier(:hosts, :tags, :unassign)
      classify_resource(host)

      post(api_host_tags_url(nil, host), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_host_url(nil, host.compressed_id)))
      expect_resource_has_tags(host, tag2[:path])
    end
  end

  context "Data Store Tag subcollection" do
    let(:ds)          { FactoryGirl.create(:storage, :name => "Storage 1", :store_type => "VMFS") }

    it "query all tags of a Data Store and verify tag category and names" do
      api_basic_authorize
      classify_resource(ds)

      get api_data_store_tags_url(nil, ds), :expand => "resources"

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Data Store without appropriate role" do
      api_basic_authorize

      post(api_data_store_tags_url(nil, ds), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Data Store" do
      api_basic_authorize subcollection_action_identifier(:data_stores, :tags, :assign)

      post(api_data_store_tags_url(nil, ds), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_data_store_url(nil, ds.compressed_id)))
    end

    it "does not unassign a tag from a Data Store without appropriate role" do
      api_basic_authorize

      post(api_data_store_tags_url(nil, ds), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Data Store" do
      api_basic_authorize subcollection_action_identifier(:data_stores, :tags, :unassign)
      classify_resource(ds)

      post(api_data_store_tags_url(nil, ds), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_data_store_url(nil, ds.compressed_id)))
      expect_resource_has_tags(ds, tag2[:path])
    end
  end

  context "Resource Pool Tag subcollection" do
    let(:rp)          { FactoryGirl.create(:resource_pool, :name => "Resource Pool 1") }

    it "query all tags of a Resource Pool and verify tag category and names" do
      api_basic_authorize
      classify_resource(rp)

      get api_resource_pool_tags_url(nil, rp), :expand => "resources"

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Resource Pool without appropriate role" do
      api_basic_authorize

      post(api_resource_pool_tags_url(nil, rp), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Resource Pool" do
      api_basic_authorize subcollection_action_identifier(:resource_pools, :tags, :assign)

      post(api_resource_pool_tags_url(nil, rp), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_resource_pool_url(nil, rp.compressed_id)))
    end

    it "does not unassign a tag from a Resource Pool without appropriate role" do
      api_basic_authorize

      post(api_resource_pool_tags_url(nil, rp), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Resource Pool" do
      api_basic_authorize subcollection_action_identifier(:resource_pools, :tags, :unassign)
      classify_resource(rp)

      post(api_resource_pool_tags_url(nil, rp), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_resource_pool_url(nil, rp.compressed_id)))
      expect_resource_has_tags(rp, tag2[:path])
    end
  end

  context "Cluster Tag subcollection" do
    let(:cluster) do
      FactoryGirl.create(:ems_cluster,
                         :name                  => "cluster 1",
                         :ext_management_system => ems,
                         :hosts                 => [host],
                         :vms                   => [])
    end

    it "query all tags of a Cluster and verify tag category and names" do
      api_basic_authorize
      classify_resource(cluster)

      get api_cluster_tags_url(nil, cluster), :expand => "resources"

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Cluster without appropriate role" do
      api_basic_authorize

      post(api_cluster_tags_url(nil, cluster), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Cluster" do
      api_basic_authorize subcollection_action_identifier(:clusters, :tags, :assign)

      post(api_cluster_tags_url(nil, cluster), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_cluster_url(nil, cluster.compressed_id)))
    end

    it "does not unassign a tag from a Cluster without appropriate role" do
      api_basic_authorize

      post(api_cluster_tags_url(nil, cluster), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Cluster" do
      api_basic_authorize subcollection_action_identifier(:clusters, :tags, :unassign)
      classify_resource(cluster)

      post(api_cluster_tags_url(nil, cluster), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_cluster_url(nil, cluster.compressed_id)))
      expect_resource_has_tags(cluster, tag2[:path])
    end
  end

  context "Service Tag subcollection" do
    let(:service)          { FactoryGirl.create(:service) }

    it "query all tags of a Service and verify tag category and names" do
      api_basic_authorize
      classify_resource(service)

      get api_service_tags_url(nil, service), :expand => "resources"

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Service without appropriate role" do
      api_basic_authorize

      post(api_service_tags_url(nil, service), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Service" do
      api_basic_authorize subcollection_action_identifier(:services, :tags, :assign)

      post(api_service_tags_url(nil, service), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_service_url(nil, service.compressed_id)))
    end

    it "does not unassign a tag from a Service without appropriate role" do
      api_basic_authorize

      post(api_service_tags_url(nil, service), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Service" do
      api_basic_authorize subcollection_action_identifier(:services, :tags, :unassign)
      classify_resource(service)

      post(api_service_tags_url(nil, service), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_service_url(nil, service.compressed_id)))
      expect_resource_has_tags(service, tag2[:path])
    end
  end

  context "Service Template Tag subcollection" do
    let(:service_template)          { FactoryGirl.create(:service_template) }

    it "query all tags of a Service Template and verify tag category and names" do
      api_basic_authorize
      classify_resource(service_template)

      get api_service_template_tags_url(nil, service_template), :expand => "resources"

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Service Template without appropriate role" do
      api_basic_authorize

      post(api_service_template_tags_url(nil, service_template), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Service Template" do
      api_basic_authorize subcollection_action_identifier(:service_templates, :tags, :assign)

      post(api_service_template_tags_url(nil, service_template), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_service_template_url(nil, service_template.compressed_id)))
    end

    it "does not unassign a tag from a Service Template without appropriate role" do
      api_basic_authorize

      post(api_service_template_tags_url(nil, service_template), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Service Template" do
      api_basic_authorize subcollection_action_identifier(:service_templates, :tags, :unassign)
      classify_resource(service_template)

      post(api_service_template_tags_url(nil, service_template), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_service_template_url(nil, service_template.compressed_id)))
      expect_resource_has_tags(service_template, tag2[:path])
    end
  end

  context "Tenant Tag subcollection" do
    let(:tenant)          { FactoryGirl.create(:tenant, :name => "Tenant A", :description => "Tenant A Description") }

    it "query all tags of a Tenant and verify tag category and names" do
      api_basic_authorize
      classify_resource(tenant)

      get api_tenant_tags_url(nil, tenant), :expand => "resources"

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Tenant without appropriate role" do
      api_basic_authorize

      post(api_tenant_tags_url(nil, tenant), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Tenant" do
      api_basic_authorize subcollection_action_identifier(:tenants, :tags, :assign)

      post(api_tenant_tags_url(nil, tenant), gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_tenant_url(nil, tenant.compressed_id)))
    end

    it "does not unassign a tag from a Tenant without appropriate role" do
      api_basic_authorize

      post(api_tenant_tags_url(nil, tenant), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Tenant" do
      api_basic_authorize subcollection_action_identifier(:tenants, :tags, :unassign)
      classify_resource(tenant)

      post(api_tenant_tags_url(nil, tenant), gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_tenant_url(nil, tenant.compressed_id)))
      expect_resource_has_tags(tenant, tag2[:path])
    end
  end

  context "Blueprint Tag subcollection" do
    it "can list all the tags of a blueprint" do
      api_basic_authorize
      blueprint = FactoryGirl.create(:blueprint)

      get(api_blueprint_tags_url(nil, blueprint))

      expect(response).to have_http_status(:ok)
    end

    it "can assign a tag to a blueprint with an appropriate role" do
      api_basic_authorize subcollection_action_identifier(:blueprints, :tags, :assign)
      blueprint = FactoryGirl.create(:blueprint)

      post(api_blueprint_tags_url(nil, blueprint),
               :action   => "assign",
               :category => tag1[:category],
               :name     => tag1[:name])

      expect(response).to have_http_status(:ok)
    end

    it "can unassign a tag from a bluepring with an appropriate role" do
      api_basic_authorize subcollection_action_identifier(:blueprints, :tags, :unassign)
      blueprint = FactoryGirl.create(:blueprint)
      classify_resource(blueprint)

      post(api_blueprint_tags_url(nil, blueprint),
               :action   => "unassign",
               :category => tag1[:category],
               :name     => tag1[:name])

      expect(response).to have_http_status(:ok)
    end

    it "will not assign tags to blueprints without an appropriate role" do
      api_basic_authorize
      blueprint = FactoryGirl.create(:blueprint)

      post(api_blueprint_tags_url(nil, blueprint),
               :action   => "assign",
               :category => tag1[:category],
               :name     => tag1[:name])

      expect(response).to have_http_status(:forbidden)
    end

    it "will not unassign tags from blueprints without an approiate role" do
      api_basic_authorize
      blueprint = FactoryGirl.create(:blueprint)
      classify_resource(blueprint)

      post(api_blueprint_tags_url(nil, blueprint),
               :action   => "unassign",
               :category => tag1[:category],
               :name     => tag1[:name])

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'Vm assign_tags action' do
    let(:bad_tag) { {:category => "cc", :name => "002"} }
    let(:vm1)                { FactoryGirl.create(:vm_vmware,    :host => host, :ems_id => ems.id) }
    let(:vm2)                { FactoryGirl.create(:vm_vmware,    :host => host, :ems_id => ems.id) }

    it 'can bulk assign tags to multiple vms' do
      api_basic_authorize collection_action_identifier(:vms, :assign_tags)
      request_body = {
        'action'    => 'assign_tags',
        'resources' => [
          { 'id' => vm1.id, 'tags' => [{ 'category' => tag1[:category], 'name' => tag1[:name] }] },
          { 'id' => vm2.id, 'tags' => [{ 'category' => tag2[:category], 'name' => tag2[:name] }] }
        ]
      }

      post(api_vms_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can bulk assign tags to multiple vms by href' do
      api_basic_authorize collection_action_identifier(:vms, :assign_tags)
      request_body = {
        'action'    => 'assign_tags',
        'resources' => [
          { 'href' => api_vm_url(nil, vm1), 'tags' => [{ 'category' => tag1[:category], 'name' => tag1[:name] }] },
          { 'href' => api_vm_url(nil, vm2), 'tags' => [{ 'category' => tag2[:category], 'name' => tag2[:name] }] }
        ]
      }

      post(api_vms_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_vm_url(nil, vm1.compressed_id)),
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_vm_url(nil, vm2.compressed_id)),
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will return success and failure messages for each vm and tag' do
      api_basic_authorize collection_action_identifier(:vms, :assign_tags)
      request_body = {
        'action'    => 'assign_tags',
        'resources' => [
          { 'id' => 999_999, 'tags' => [{'category' => 'department', 'name' => 'finance'}] },
          { 'id' => vm2.id, 'tags' => [
            {'category' => bad_tag[:category], 'name' => bad_tag[:name]},
            {'category' => tag1[:category], 'name' => tag1[:name]}
          ]}
        ]
      }

      post(api_vms_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success' => false, 'message' => a_string_including("Couldn't find Vm")),
          a_hash_including('success'      => false,
                           'href'         => a_string_including(api_vm_url(nil, vm2.compressed_id)),
                           'tag_category' => bad_tag[:category],
                           'tag_name'     => bad_tag[:name]),
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_vm_url(nil, vm2.compressed_id)),
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'fails without an appropriate role' do
      api_basic_authorize

      post(api_vms_url, :action => 'assign_tags')

      expect(response).to have_http_status(:forbidden)
    end

    it 'can bulk assign tags by href' do
      api_basic_authorize collection_action_identifier(:vms, :assign_tags)
      request_body = {
        'action'    => 'assign_tags',
        'resources' => [
          { 'id' => vm1.id, 'tags' => [{'href' => api_tag_url(nil, Tag.find_by(:name => tag1[:path]))}] },
          { 'id' => vm2.id, 'tags' => [{'href' => api_tag_url(nil, Tag.find_by(:name => tag2[:path]))}] }
        ]
      }

      post(api_vms_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_vm_url(nil, vm1.compressed_id)),
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_vm_url(nil, vm2.compressed_id)),
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can bulk assign tags by id' do
      api_basic_authorize collection_action_identifier(:vms, :assign_tags)
      request_body = {
        'action'    => 'assign_tags',
        'resources' => [
          { 'id' => vm1.id, 'tags' => [{'id' => Tag.find_by(:name => tag1[:path]).id}] },
          { 'id' => vm2.id, 'tags' => [{'id' => Tag.find_by(:name => tag2[:path]).id}] }
        ]
      }

      post(api_vms_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'Services assign_tags action' do
    let(:bad_tag) { {:category => "cc", :name => "002"} }
    let(:service1)                { FactoryGirl.create(:service) }
    let(:service2)                { FactoryGirl.create(:service) }

    it 'can bulk assign tags to multiple services' do
      api_basic_authorize collection_action_identifier(:services, :assign_tags)
      request_body = {
        'action'    => 'assign_tags',
        'resources' => [
          { 'id' => service1.id, 'tags' => [{ 'category' => tag1[:category], 'name' => tag1[:name] }] },
          { 'id' => service2.id, 'tags' => [{ 'category' => tag2[:category], 'name' => tag2[:name] }] }
        ]
      }

      post(api_services_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can bulk assign tags to multiple services by href' do
      api_basic_authorize collection_action_identifier(:services, :assign_tags)
      request_body = {
        'action'    => 'assign_tags',
        'resources' => [
          { 'href' => api_service_url(nil, service1), 'tags' => [{ 'category' => tag1[:category], 'name' => tag1[:name] }] },
          { 'href' => api_service_url(nil, service2), 'tags' => [{ 'category' => tag2[:category], 'name' => tag2[:name] }] }
        ]
      }

      post(api_services_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will return success and failure messages for each service and tag' do
      api_basic_authorize collection_action_identifier(:services, :assign_tags)
      request_body = {
        'action'    => 'assign_tags',
        'resources' => [
          { 'id' => 999_999, 'tags' => [{'category' => 'department', 'name' => 'finance'}] },
          { 'id' => service2.id, 'tags' => [
            {'category' => bad_tag[:category], 'name' => bad_tag[:name]},
            {'category' => tag1[:category], 'name' => tag1[:name]}
          ]}
        ]
      }

      post(api_services_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success' => false, 'message' => a_string_including("Couldn't find Service")),
          a_hash_including('success'      => false,
                           'tag_category' => bad_tag[:category],
                           'tag_name'     => bad_tag[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'fails without an appropriate role' do
      api_basic_authorize

      post(api_services_url, :action => 'assign_tags')

      expect(response).to have_http_status(:forbidden)
    end

    it 'can bulk assign tags by href' do
      api_basic_authorize collection_action_identifier(:services, :assign_tags)
      request_body = {
        'action'    => 'assign_tags',
        'resources' => [
          { 'id' => service1.id, 'tags' => [{'href' => api_tag_url(nil, Tag.find_by(:name => tag1[:path]))}] },
          { 'id' => service2.id, 'tags' => [{'href' => api_tag_url(nil, Tag.find_by(:name => tag2[:path]))}] }
        ]
      }

      post(api_services_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can bulk assign tags by id' do
      api_basic_authorize collection_action_identifier(:services, :assign_tags)
      request_body = {
        'action'    => 'assign_tags',
        'resources' => [
          { 'id' => service1.id, 'tags' => [{'id' => Tag.find_by(:name => tag1[:path]).id}] },
          { 'id' => service2.id, 'tags' => [{'id' => Tag.find_by(:name => tag2[:path]).id}] }
        ]
      }

      post(api_services_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'Services unassign_tags action' do
    let(:bad_tag) { {:category => "cc", :name => "002"} }
    let(:service1)                { FactoryGirl.create(:service) }
    let(:service2)                { FactoryGirl.create(:service) }

    before do
      classify_resource(service1)
      classify_resource(service2)
    end

    it 'can bulk unassign tags on multiple services' do
      api_basic_authorize collection_action_identifier(:services, :unassign_tags)
      request_body = {
        'action'    => 'unassign_tags',
        'resources' => [
          { 'id' => service1.id, 'tags' => [{ 'category' => tag1[:category], 'name' => tag1[:name] }] },
          { 'id' => service2.id, 'tags' => [{ 'category' => tag2[:category], 'name' => tag2[:name] }] }
        ]
      }

      post(api_services_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_service_url(nil, service1.compressed_id)),
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_service_url(nil, service2.compressed_id)),
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can bulk unassign tags to multiple services by href' do
      api_basic_authorize collection_action_identifier(:services, :unassign_tags)
      request_body = {
        'action'    => 'unassign_tags',
        'resources' => [
          { 'href' => api_service_url(nil, service1), 'tags' => [{ 'category' => tag1[:category], 'name' => tag1[:name] }] },
          { 'href' => api_service_url(nil, service2), 'tags' => [{ 'category' => tag2[:category], 'name' => tag2[:name] }] }
        ]
      }

      post(api_services_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_service_url(nil, service1.compressed_id)),
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_service_url(nil, service2.compressed_id)),
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will return success and failure messages for each service and tag' do
      api_basic_authorize collection_action_identifier(:services, :unassign_tags)
      request_body = {
        'action'    => 'unassign_tags',
        'resources' => [
          { 'id' => 999_999, 'tags' => [{'category' => 'department', 'name' => 'finance'}] },
          { 'id' => service2.id, 'tags' => [
            {'category' => bad_tag[:category], 'name' => bad_tag[:name]},
            {'category' => tag1[:category], 'name' => tag1[:name]}
          ]}
        ]
      }

      post(api_services_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success' => false, 'message' => a_string_including("Couldn't find Service")),
          a_hash_including('success'      => true,
                           'message'      => a_string_including("Not tagged with Tag: category:'cc' name:'002'"),
                           'tag_category' => bad_tag[:category],
                           'tag_name'     => bad_tag[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'fails without an appropriate role' do
      api_basic_authorize

      post(api_services_url, :action => 'unassign_tags')

      expect(response).to have_http_status(:forbidden)
    end

    it 'can bulk unassign tags by href' do
      api_basic_authorize collection_action_identifier(:services, :unassign_tags)
      request_body = {
        'action'    => 'unassign_tags',
        'resources' => [
          { 'id' => service1.id, 'tags' => [{'href' => api_tag_url(nil, Tag.find_by(:name => tag1[:path]))}] },
          { 'id' => service2.id, 'tags' => [{'href' => api_tag_url(nil, Tag.find_by(:name => tag2[:path]))}] }
        ]
      }

      post(api_services_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can bulk unassign tags by id' do
      api_basic_authorize collection_action_identifier(:services, :unassign_tags)
      request_body = {
        'action'    => 'unassign_tags',
        'resources' => [
          { 'id' => service1.id, 'tags' => [{'id' => Tag.find_by(:name => tag1[:path]).id}] },
          { 'id' => service2.id, 'tags' => [{'id' => Tag.find_by(:name => tag2[:path]).id}] }
        ]
      }

      post(api_services_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'Vms unassign_tags action' do
    let(:bad_tag) { {:category => "cc", :name => "002"} }
    let(:vm1)                { FactoryGirl.create(:vm_vmware,    :host => host, :ems_id => ems.id) }
    let(:vm2)                { FactoryGirl.create(:vm_vmware,    :host => host, :ems_id => ems.id) }

    before do
      classify_resource(vm1)
      classify_resource(vm2)
    end

    it 'can bulk unassign tags on multiple vms' do
      api_basic_authorize collection_action_identifier(:vms, :unassign_tags)
      request_body = {
        'action'    => 'unassign_tags',
        'resources' => [
          { 'id' => vm1.id, 'tags' => [{ 'category' => tag1[:category], 'name' => tag1[:name] }] },
          { 'id' => vm2.id, 'tags' => [{ 'category' => tag2[:category], 'name' => tag2[:name] }] }
        ]
      }

      post(api_vms_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can bulk unassign tags to multiple vms by href' do
      api_basic_authorize collection_action_identifier(:vms, :unassign_tags)
      request_body = {
        'action'    => 'unassign_tags',
        'resources' => [
          { 'href' => api_vm_url(nil, vm1), 'tags' => [{ 'category' => tag1[:category], 'name' => tag1[:name] }] },
          { 'href' => api_vm_url(nil, vm2), 'tags' => [{ 'category' => tag2[:category], 'name' => tag2[:name] }] }
        ]
      }

      post(api_vms_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will return success and failure messages for each vm and tag' do
      api_basic_authorize collection_action_identifier(:vms, :unassign_tags)
      request_body = {
        'action'    => 'unassign_tags',
        'resources' => [
          { 'id' => 999_999, 'tags' => [{'category' => 'department', 'name' => 'finance'}] },
          { 'id' => vm2.id, 'tags' => [
            {'category' => bad_tag[:category], 'name' => bad_tag[:name]},
            {'category' => tag1[:category], 'name' => tag1[:name]}
          ]}
        ]
      }

      post(api_vms_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success' => false, 'message' => a_string_including("Couldn't find Vm")),
          a_hash_including('success'      => true,
                           'message'      => a_string_including("Not tagged with Tag: category:'cc' name:'002'"),
                           'tag_category' => bad_tag[:category],
                           'tag_name'     => bad_tag[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'fails without an appropriate role' do
      api_basic_authorize

      post(api_vms_url, :action => 'unassign_tags')

      expect(response).to have_http_status(:forbidden)
    end

    it 'can bulk unassign tags by href' do
      api_basic_authorize collection_action_identifier(:vms, :unassign_tags)
      request_body = {
        'action'    => 'unassign_tags',
        'resources' => [
          { 'id' => vm1.id, 'tags' => [{'href' => api_tag_url(nil, Tag.find_by(:name => tag1[:path]))}] },
          { 'id' => vm2.id, 'tags' => [{'href' => api_tag_url(nil, Tag.find_by(:name => tag2[:path]))}] }
        ]
      }

      post(api_vms_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can bulk unassign tags by id' do
      api_basic_authorize collection_action_identifier(:vms, :unassign_tags)
      request_body = {
        'action'    => 'unassign_tags',
        'resources' => [
          { 'id' => vm1.id, 'tags' => [{'id' => Tag.find_by(:name => tag1[:path]).id}] },
          { 'id' => vm2.id, 'tags' => [{'id' => Tag.find_by(:name => tag2[:path]).id}] }
        ]
      }

      post(api_vms_url, request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'tag_category' => tag2[:category],
                           'tag_name'     => tag2[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
