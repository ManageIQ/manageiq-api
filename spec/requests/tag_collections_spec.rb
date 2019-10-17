#
# REST API Request Tests - Tags subcollection specs for Non-Vm collections
#
describe "Tag Collections API" do
  let(:zone)         { FactoryBot.create(:zone, :name => "api_zone") }
  let(:ems)          { FactoryBot.create(:ems_vmware, :zone => zone) }
  let(:host)         { FactoryBot.create(:host) }

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
    FactoryBot.create(:classification_department_with_tags)
    FactoryBot.create(:classification_cost_center_with_tags)
  end

  context "Availability Zone Tag subcollection" do
    let(:availability_zone) { FactoryBot.create(:availability_zone) }

    it "query all tags of an Availability Zone and verify tag category and names" do
      api_basic_authorize
      classify_resource(availability_zone)

      get api_availability_zone_tags_url(nil, availability_zone), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to an Availability Zone without appropriate role" do
      api_basic_authorize

      post(api_availability_zone_tags_url(nil, availability_zone), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to an Availability Zone" do
      api_basic_authorize subcollection_action_identifier(:availability_zones, :tags, :assign)

      post(api_availability_zone_tags_url(nil, availability_zone), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_availability_zone_url(nil, availability_zone)))
    end

    it "does not unassign a tag from an Availability Zone without appropriate role" do
      api_basic_authorize

      post(api_availability_zone_tags_url(nil, availability_zone), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from an Availability Zone" do
      api_basic_authorize subcollection_action_identifier(:availability_zones, :tags, :unassign)
      classify_resource(availability_zone)

      post(api_availability_zone_tags_url(nil, availability_zone), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_availability_zone_url(nil, availability_zone)))
      expect_resource_has_tags(availability_zone, tag2[:path])
    end
  end

  context "Cloud Network Tag subcollection" do
    let(:cloud_network) { FactoryBot.create(:cloud_network) }

    it "query all tags of an Cloud Network and verify tag category and names" do
      api_basic_authorize
      classify_resource(cloud_network)

      get api_cloud_network_tags_url(nil, cloud_network), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to an Cloud Network without appropriate role" do
      api_basic_authorize

      post(api_cloud_network_tags_url(nil, cloud_network), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to an Cloud Network" do
      api_basic_authorize subcollection_action_identifier(:cloud_networks, :tags, :assign)

      post(api_cloud_network_tags_url(nil, cloud_network), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_cloud_network_url(nil, cloud_network)))
    end

    it "does not unassign a tag from an Cloud Network without appropriate role" do
      api_basic_authorize

      post(api_cloud_network_tags_url(nil, cloud_network), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from an Cloud Network" do
      api_basic_authorize subcollection_action_identifier(:cloud_networks, :tags, :unassign)
      classify_resource(cloud_network)

      post(api_cloud_network_tags_url(nil, cloud_network), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_cloud_network_url(nil, cloud_network)))
      expect_resource_has_tags(cloud_network, tag2[:path])
    end
  end

  context "Cloud Subnet Tag subcollection" do
    let(:cloud_subnet) { FactoryBot.create(:cloud_subnet) }

    it "query all tags of a Cloud Subnet and verify tag category and names" do
      api_basic_authorize
      classify_resource(cloud_subnet)

      get api_cloud_subnet_tags_url(nil, cloud_subnet), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Cloud Subnet without appropriate role" do
      api_basic_authorize

      post(api_cloud_subnet_tags_url(nil, cloud_subnet), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Cloud Subnet" do
      api_basic_authorize subcollection_action_identifier(:cloud_subnets, :tags, :assign)

      post(api_cloud_subnet_tags_url(nil, cloud_subnet), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_cloud_subnet_url(nil, cloud_subnet)))
    end

    it "does not unassign a tag from a Cloud Subnet without appropriate role" do
      api_basic_authorize

      post(api_cloud_subnet_tags_url(nil, cloud_subnet), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Cloud Subnet" do
      api_basic_authorize subcollection_action_identifier(:cloud_subnets, :tags, :unassign)
      classify_resource(cloud_subnet)

      post(api_cloud_subnet_tags_url(nil, cloud_subnet), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_cloud_subnet_url(nil, cloud_subnet)))
      expect_resource_has_tags(cloud_subnet, tag2[:path])
    end
  end

  context "Flavor Tag subcollection" do
    let(:flavor) { FactoryBot.create(:flavor) }

    it "query all tags of a Flavor and verify tag category and names" do
      api_basic_authorize
      classify_resource(flavor)

      get api_flavor_tags_url(nil, flavor), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Flavor without appropriate role" do
      api_basic_authorize

      post(api_flavor_tags_url(nil, flavor), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Flavor" do
      api_basic_authorize subcollection_action_identifier(:flavors, :tags, :assign)

      post(api_flavor_tags_url(nil, flavor), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_flavor_url(nil, flavor)))
    end

    it "does not unassign a tag from a Flavor without appropriate role" do
      api_basic_authorize

      post(api_flavor_tags_url(nil, flavor), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Flavor" do
      api_basic_authorize subcollection_action_identifier(:flavors, :tags, :unassign)
      classify_resource(flavor)

      post(api_flavor_tags_url(nil, flavor), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_flavor_url(nil, flavor)))
      expect_resource_has_tags(flavor, tag2[:path])
    end
  end

  context "Network Router Tag subcollection" do
    let(:network_router) { FactoryBot.create(:network_router) }

    it "query all tags of a Network Router and verify tag category and names" do
      api_basic_authorize
      classify_resource(network_router)

      get api_network_router_tags_url(nil, network_router), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Network Router without appropriate role" do
      api_basic_authorize

      post(api_network_router_tags_url(nil, network_router), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Network Router" do
      api_basic_authorize subcollection_action_identifier(:network_routers, :tags, :assign)

      post(api_network_router_tags_url(nil, network_router), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_network_router_url(nil, network_router)))
    end

    it "does not unassign a tag from a Network Router without appropriate role" do
      api_basic_authorize

      post(api_network_router_tags_url(nil, network_router), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Network Router" do
      api_basic_authorize subcollection_action_identifier(:network_routers, :tags, :unassign)
      classify_resource(network_router)

      post(api_network_router_tags_url(nil, network_router), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_network_router_url(nil, network_router)))
      expect_resource_has_tags(network_router, tag2[:path])
    end
  end

  context "Provider Tag subcollection" do
    let(:provider)          { ems }

    it "query all tags of a Provider and verify tag category and names" do
      api_basic_authorize
      classify_resource(provider)

      get api_provider_tags_url(nil, provider), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Provider without appropriate role" do
      api_basic_authorize

      post(api_provider_tags_url(nil, provider), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Provider" do
      api_basic_authorize subcollection_action_identifier(:providers, :tags, :assign)

      post(api_provider_tags_url(nil, provider), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_provider_url(nil, provider)))
    end

    it "does not unassign a tag from a Provider without appropriate role" do
      api_basic_authorize

      post(api_provider_tags_url(nil, provider), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Provider" do
      api_basic_authorize subcollection_action_identifier(:providers, :tags, :unassign)
      classify_resource(provider)

      post(api_provider_tags_url(nil, provider), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_provider_url(nil, provider)))
      expect_resource_has_tags(provider, tag2[:path])
    end
  end

  context "Host Tag subcollection" do
    it "query all tags of a Host and verify tag category and names" do
      api_basic_authorize
      classify_resource(host)

      get api_host_tags_url(nil, host), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Host without appropriate role" do
      api_basic_authorize

      post(api_host_tags_url(nil, host), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Host" do
      api_basic_authorize subcollection_action_identifier(:hosts, :tags, :assign)

      post(api_host_tags_url(nil, host), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_host_url(nil, host)))
    end

    it "does not unassign a tag from a Host without appropriate role" do
      api_basic_authorize

      post(api_host_tags_url(nil, host), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Host" do
      api_basic_authorize subcollection_action_identifier(:hosts, :tags, :unassign)
      classify_resource(host)

      post(api_host_tags_url(nil, host), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_host_url(nil, host)))
      expect_resource_has_tags(host, tag2[:path])
    end
  end

  context "Data Store Tag subcollection" do
    let(:ds)          { FactoryBot.create(:storage, :name => "Storage 1", :store_type => "VMFS") }

    it "query all tags of a Data Store and verify tag category and names" do
      api_basic_authorize
      classify_resource(ds)

      get api_data_store_tags_url(nil, ds), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Data Store without appropriate role" do
      api_basic_authorize

      post(api_data_store_tags_url(nil, ds), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Data Store" do
      api_basic_authorize subcollection_action_identifier(:data_stores, :tags, :assign)

      post(api_data_store_tags_url(nil, ds), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_data_store_url(nil, ds)))
    end

    it "does not unassign a tag from a Data Store without appropriate role" do
      api_basic_authorize

      post(api_data_store_tags_url(nil, ds), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Data Store" do
      api_basic_authorize subcollection_action_identifier(:data_stores, :tags, :unassign)
      classify_resource(ds)

      post(api_data_store_tags_url(nil, ds), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_data_store_url(nil, ds)))
      expect_resource_has_tags(ds, tag2[:path])
    end
  end

  context "Resource Pool Tag subcollection" do
    let(:rp)          { FactoryBot.create(:resource_pool, :name => "Resource Pool 1") }

    it "query all tags of a Resource Pool and verify tag category and names" do
      api_basic_authorize
      classify_resource(rp)

      get api_resource_pool_tags_url(nil, rp), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Resource Pool without appropriate role" do
      api_basic_authorize

      post(api_resource_pool_tags_url(nil, rp), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Resource Pool" do
      api_basic_authorize subcollection_action_identifier(:resource_pools, :tags, :assign)

      post(api_resource_pool_tags_url(nil, rp), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_resource_pool_url(nil, rp)))
    end

    it "does not unassign a tag from a Resource Pool without appropriate role" do
      api_basic_authorize

      post(api_resource_pool_tags_url(nil, rp), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Resource Pool" do
      api_basic_authorize subcollection_action_identifier(:resource_pools, :tags, :unassign)
      classify_resource(rp)

      post(api_resource_pool_tags_url(nil, rp), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_resource_pool_url(nil, rp)))
      expect_resource_has_tags(rp, tag2[:path])
    end
  end

  context "Cluster Tag subcollection" do
    let(:cluster) do
      FactoryBot.create(:ems_cluster,
                         :name                  => "cluster 1",
                         :ext_management_system => ems,
                         :hosts                 => [host],
                         :vms                   => [])
    end

    it "query all tags of a Cluster and verify tag category and names" do
      api_basic_authorize
      classify_resource(cluster)

      get api_cluster_tags_url(nil, cluster), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Cluster without appropriate role" do
      api_basic_authorize

      post(api_cluster_tags_url(nil, cluster), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Cluster" do
      api_basic_authorize subcollection_action_identifier(:clusters, :tags, :assign)

      post(api_cluster_tags_url(nil, cluster), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_cluster_url(nil, cluster)))
    end

    it "does not unassign a tag from a Cluster without appropriate role" do
      api_basic_authorize

      post(api_cluster_tags_url(nil, cluster), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Cluster" do
      api_basic_authorize subcollection_action_identifier(:clusters, :tags, :unassign)
      classify_resource(cluster)

      post(api_cluster_tags_url(nil, cluster), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_cluster_url(nil, cluster)))
      expect_resource_has_tags(cluster, tag2[:path])
    end
  end

  context "Security Group Tag subcollection" do
    let(:security_group) { FactoryBot.create(:security_group) }

    it "query all tags of a Security Group and verify tag category and names" do
      api_basic_authorize
      classify_resource(security_group)

      get api_security_group_tags_url(nil, security_group), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Security Group without appropriate role" do
      api_basic_authorize

      post(api_security_group_tags_url(nil, security_group), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Security Group" do
      api_basic_authorize subcollection_action_identifier(:security_groups, :tags, :assign)

      post(api_security_group_tags_url(nil, security_group), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_security_group_url(nil, security_group)))
    end

    it "does not unassign a tag from a Security Group without appropriate role" do
      api_basic_authorize

      post(api_security_group_tags_url(nil, security_group), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Security Group" do
      api_basic_authorize subcollection_action_identifier(:security_groups, :tags, :unassign)
      classify_resource(security_group)

      post(api_security_group_tags_url(nil, security_group), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_security_group_url(nil, security_group)))
      expect_resource_has_tags(security_group, tag2[:path])
    end
  end

  context "Service Tag subcollection" do
    let(:service)          { FactoryBot.create(:service) }

    it "query all tags of a Service and verify tag category and names" do
      api_basic_authorize
      classify_resource(service)

      get api_service_tags_url(nil, service), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Service without appropriate role" do
      api_basic_authorize

      post(api_service_tags_url(nil, service), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Service" do
      api_basic_authorize subcollection_action_identifier(:services, :tags, :assign)

      post(api_service_tags_url(nil, service), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_service_url(nil, service)))
    end

    it "does not unassign a tag from a Service without appropriate role" do
      api_basic_authorize

      post(api_service_tags_url(nil, service), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Service" do
      api_basic_authorize subcollection_action_identifier(:services, :tags, :unassign)
      classify_resource(service)

      post(api_service_tags_url(nil, service), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_service_url(nil, service)))
      expect_resource_has_tags(service, tag2[:path])
    end
  end

  context "Service Template Tag subcollection" do
    let(:service_template)          { FactoryBot.create(:service_template) }

    it "query all tags of a Service Template and verify tag category and names" do
      api_basic_authorize
      classify_resource(service_template)

      get api_service_template_tags_url(nil, service_template), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Service Template without appropriate role" do
      api_basic_authorize

      post(api_service_template_tags_url(nil, service_template), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Service Template" do
      api_basic_authorize subcollection_action_identifier(:service_templates, :tags, :assign)

      post(api_service_template_tags_url(nil, service_template), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_service_template_url(nil, service_template)))
    end

    it "does not unassign a tag from a Service Template without appropriate role" do
      api_basic_authorize

      post(api_service_template_tags_url(nil, service_template), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Service Template" do
      api_basic_authorize subcollection_action_identifier(:service_templates, :tags, :unassign)
      classify_resource(service_template)

      post(api_service_template_tags_url(nil, service_template), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_service_template_url(nil, service_template)))
      expect_resource_has_tags(service_template, tag2[:path])
    end
  end

  context "Tenant Tag subcollection" do
    let(:tenant)          { FactoryBot.create(:tenant, :name => "Tenant A", :description => "Tenant A Description") }

    it "query all tags of a Tenant and verify tag category and names" do
      api_basic_authorize
      classify_resource(tenant)

      get api_tenant_tags_url(nil, tenant), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Tenant without appropriate role" do
      api_basic_authorize

      post(api_tenant_tags_url(nil, tenant), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Tenant" do
      api_basic_authorize subcollection_action_identifier(:tenants, :tags, :assign)

      post(api_tenant_tags_url(nil, tenant), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_tenant_url(nil, tenant)))
    end

    it "does not unassign a tag from a Tenant without appropriate role" do
      api_basic_authorize

      post(api_tenant_tags_url(nil, tenant), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Tenant" do
      api_basic_authorize subcollection_action_identifier(:tenants, :tags, :unassign)
      classify_resource(tenant)

      post(api_tenant_tags_url(nil, tenant), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_tenant_url(nil, tenant)))
      expect_resource_has_tags(tenant, tag2[:path])
    end
  end

  context 'Vm assign_tags action' do
    let(:bad_tag) { {:category => "cc", :name => "002"} }
    let(:vm1)                { FactoryBot.create(:vm_vmware,    :host => host, :ems_id => ems.id) }
    let(:vm2)                { FactoryBot.create(:vm_vmware,    :host => host, :ems_id => ems.id) }

    it 'can bulk assign tags to multiple vms' do
      api_basic_authorize collection_action_identifier(:vms, :assign_tags)
      request_body = {
        'action'    => 'assign_tags',
        'resources' => [
          { 'id' => vm1.id, 'tags' => [{ 'category' => tag1[:category], 'name' => tag1[:name] }] },
          { 'id' => vm2.id, 'tags' => [{ 'category' => tag2[:category], 'name' => tag2[:name] }] }
        ]
      }

      post(api_vms_url, :params => request_body)

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

      post(api_vms_url, :params => request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_vm_url(nil, vm1)),
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_vm_url(nil, vm2)),
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

      post(api_vms_url, :params => request_body)

      expected = {
        'results' => [
          a_hash_including('success' => false, 'message' => a_string_including("Couldn't find Vm")),
          a_hash_including('success'      => false,
                           'href'         => a_string_including(api_vm_url(nil, vm2)),
                           'tag_category' => bad_tag[:category],
                           'tag_name'     => bad_tag[:name]),
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_vm_url(nil, vm2)),
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name])
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'fails without an appropriate role' do
      api_basic_authorize

      post(api_vms_url, :params => { :action => 'assign_tags' })

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

      post(api_vms_url, :params => request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_vm_url(nil, vm1)),
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_vm_url(nil, vm2)),
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

      post(api_vms_url, :params => request_body)

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
    let(:service1)                { FactoryBot.create(:service) }
    let(:service2)                { FactoryBot.create(:service) }

    it 'can bulk assign tags to multiple services' do
      api_basic_authorize collection_action_identifier(:services, :assign_tags)
      request_body = {
        'action'    => 'assign_tags',
        'resources' => [
          { 'id' => service1.id, 'tags' => [{ 'category' => tag1[:category], 'name' => tag1[:name] }] },
          { 'id' => service2.id, 'tags' => [{ 'category' => tag2[:category], 'name' => tag2[:name] }] }
        ]
      }

      post(api_services_url, :params => request_body)

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

      post(api_services_url, :params => request_body)

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

      post(api_services_url, :params => request_body)

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

      post(api_services_url, :params => { :action => 'assign_tags' })

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

      post(api_services_url, :params => request_body)

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

      post(api_services_url, :params => request_body)

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
    let(:service1)                { FactoryBot.create(:service) }
    let(:service2)                { FactoryBot.create(:service) }

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

      post(api_services_url, :params => request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_service_url(nil, service1)),
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_service_url(nil, service2)),
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

      post(api_services_url, :params => request_body)

      expected = {
        'results' => [
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_service_url(nil, service1)),
                           'tag_category' => tag1[:category],
                           'tag_name'     => tag1[:name]),
          a_hash_including('success'      => true,
                           'href'         => a_string_including(api_service_url(nil, service2)),
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

      post(api_services_url, :params => request_body)

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

      post(api_services_url, :params => { :action => 'unassign_tags' })

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

      post(api_services_url, :params => request_body)

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

      post(api_services_url, :params => request_body)

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
    let(:vm1)                { FactoryBot.create(:vm_vmware,    :host => host, :ems_id => ems.id) }
    let(:vm2)                { FactoryBot.create(:vm_vmware,    :host => host, :ems_id => ems.id) }

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

      post(api_vms_url, :params => request_body)

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

      post(api_vms_url, :params => request_body)

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

      post(api_vms_url, :params => request_body)

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

      post(api_vms_url, :params => { :action => 'unassign_tags' })

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

      post(api_vms_url, :params => request_body)

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

      post(api_vms_url, :params => request_body)

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

  context 'Generic Objects subcollection' do
    let(:object) { FactoryBot.create(:generic_object) }

    describe 'POST /api/generic_objects/:id/tags' do
      it 'cannot assign tags without an appropriate role' do
        api_basic_authorize

        post(api_generic_object_tags_url(nil, object), :params => { :action => 'assign' })

        expect(response).to have_http_status(:forbidden)
      end

      it 'can assign tags with an appropriate role' do
        api_basic_authorize(subcollection_action_identifier(:generic_objects, :tags, :assign))

        post(api_generic_object_tags_url(nil, object), :params => { :action => 'assign', :category => tag1[:category], :name => tag1[:name]})

        expected = {
          'results' => [
            a_hash_including('success' => true, 'message' => a_string_including('Assigning Tag'))
          ]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it 'cannot assign tags without an appropriate role' do
        api_basic_authorize

        post(api_generic_object_tags_url(nil, object), :params => { :action => 'unassign' })

        expect(response).to have_http_status(:forbidden)
      end

      it 'can unassign tags with an appropriate role' do
        Classification.classify(object, tag1[:category], tag1[:name])
        api_basic_authorize(subcollection_action_identifier(:generic_objects, :tags, :assign))

        post(api_generic_object_tags_url(nil, object), :params => { :action => 'unassign', :category => tag1[:category], :name => tag1[:name]})

        expected = {
          'results' => [
            a_hash_including('success' => true, 'message' => a_string_including('Unassigning Tag'))
          ]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end

    describe 'GET /api/generic_objects/:id/tags' do
      before do
        Classification.classify(object, tag1[:category], tag1[:name])
      end

      it 'returns tags for a generic object' do
        api_basic_authorize

        get(api_generic_object_tags_url(nil, object))

        expected = {
          'name'      => 'tags',
          'subcount'  => 1,
          'resources' => [
            { 'href' => a_string_including(api_generic_object_tags_url(nil, object)) }
          ]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end

  context "Cloud Tenant Tag subcollection" do
    let(:cloud_tenant) { FactoryBot.create(:cloud_tenant) }

    it "query all tags of a Cloud Tenant and verify tag category and names" do
      api_basic_authorize
      classify_resource(cloud_tenant)

      get api_cloud_tenant_tags_url(nil, cloud_tenant), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Cloud Tenant without appropriate role" do
      api_basic_authorize

      post(api_cloud_tenant_tags_url(nil, cloud_tenant), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Cloud Tenant" do
      api_basic_authorize subcollection_action_identifier(:cloud_tenants, :tags, :assign)

      post(api_cloud_tenant_tags_url(nil, cloud_tenant), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_cloud_tenant_url(nil, cloud_tenant)))
    end

    it "does not unassign a tag from a Cloud Tenant without appropriate role" do
      api_basic_authorize

      post(api_cloud_tenant_tags_url(nil, cloud_tenant), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Cloud Tenant" do
      api_basic_authorize subcollection_action_identifier(:cloud_tenants, :tags, :unassign)
      classify_resource(cloud_tenant)

      post(api_cloud_tenant_tags_url(nil, cloud_tenant), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_cloud_tenant_url(nil, cloud_tenant)))
      expect_resource_has_tags(cloud_tenant, tag2[:path])
    end
  end

  context "Cloud Volume Tag subcollection" do
    let(:cloud_volume) { FactoryBot.create(:cloud_volume) }

    it "query all tags of a Cloud Volume and verify tag category and names" do
      api_basic_authorize
      classify_resource(cloud_volume)

      get api_cloud_volume_tags_url(nil, cloud_volume), :params => { :expand => "resources" }

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => tag_paths)
    end

    it "does not assign a tag to a Cloud Volume without appropriate role" do
      api_basic_authorize

      post(api_cloud_volume_tags_url(nil, cloud_volume), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Cloud Volume" do
      api_basic_authorize subcollection_action_identifier(:cloud_volumes, :tags, :assign)

      post(api_cloud_volume_tags_url(nil, cloud_volume), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_cloud_volume_url(nil, cloud_volume)))
    end

    it "does not unassign a tag from a Cloud Volume without appropriate role" do
      api_basic_authorize

      post(api_cloud_volume_tags_url(nil, cloud_volume), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Cloud Volume" do
      api_basic_authorize subcollection_action_identifier(:cloud_volumes, :tags, :unassign)
      classify_resource(cloud_volume)

      post(api_cloud_volume_tags_url(nil, cloud_volume), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(tag1_results(api_cloud_volume_url(nil, cloud_volume)))
      expect_resource_has_tags(cloud_volume, tag2[:path])
    end
  end
end
