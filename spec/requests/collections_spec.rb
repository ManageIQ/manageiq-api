#
# Rest API Collections Tests
#
describe "Rest API Collections" do
  let(:zone)       { FactoryBot.create(:zone, :name => "api_zone") }
  let(:miq_server) { FactoryBot.create(:miq_server, :zone => zone) }
  let(:template) do
    FactoryBot.create(:miq_template, :name => "template 1", :vendor => "vmware", :location => "template1.vmtx")
  end

  def test_collection_query(collection, collection_url, klass, attr = :id)
    if Api::ApiConfig.fetch_path(:collections, collection, :collection_actions, :get)
      api_basic_authorize collection_action_identifier(collection, :read, :get)
    else
      api_basic_authorize
    end

    get collection_url, :params => { :expand => "resources" }

    resource_identifier = Api::CollectionConfig.new.resource_identifier(collection)
    expected_resources = klass.all.map do |record|
      a_hash_including(
        attr.to_s => record.send(attr).to_s,
        "href"    => "#{collection_url}/#{record.send(resource_identifier)}"
      )
    end

    expected = {
      "name"      => collection.to_s,
      "count"     => klass.count,
      "subcount"  => klass.count,
      "resources" => match_array(expected_resources)
    }

    expect(response.parsed_body).to include(expected)
  end

  def test_collection_bulk_query(collection, collection_url, klass, id = nil)
    api_basic_authorize collection_action_identifier(collection, :query)

    obj = id.nil? ? klass.first : klass.find(id)
    url = send("api_#{collection.to_s.singularize}_url", nil, obj.id.to_s)
    attr_list = String(Api::ApiConfig.collections[collection].identifying_attrs).split(",")
    attr_list |= %w(guid) if klass.attribute_method?(:guid)
    resources = [{"id" => obj.id.to_s}, {"href" => url}]
    attr_list.each { |attr| resources << {attr => obj.public_send(attr)} }

    post(collection_url, :params => gen_request(:query, resources))

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["results"].size).to eq(resources.size)
    expect(response.parsed_body).to include(
      "results" => all(
        a_hash_including("id" => obj.id.to_s, "href" => url)
      )
    )
  end

  context "Collections" do
    it "query Automate Domains" do
      FactoryBot.create(:miq_ae_domain)
      test_collection_query(:automate_domains, api_automate_domains_url, MiqAeDomain)
    end

    it "query Automation Requests" do
      FactoryBot.create(:automation_request, :requester => @user)
      test_collection_query(:automation_requests, api_automation_requests_url, AutomationRequest)
    end

    it "query Availability Zones" do
      FactoryBot.create(:availability_zone)
      test_collection_query(:availability_zones, api_availability_zones_url, AvailabilityZone)
    end

    it "query Categories" do
      FactoryBot.create(:category)
      test_collection_query(:categories, api_categories_url, Category)
    end

    it "query Chargebacks" do
      FactoryBot.create(:chargeback_rate)
      test_collection_query(:chargebacks, api_chargebacks_url, ChargebackRate)
    end

    it "query Containers" do
      FactoryBot.create(:container)
      test_collection_query(:containers, api_containers_url, Container)
    end

    it "query ContainerGroups" do
      FactoryBot.create(:container_group)
      test_collection_query(:container_groups, api_container_groups_url, ContainerGroup)
    end

    it "query ContainerImage" do
      FactoryBot.create(:container_image)
      test_collection_query(:container_images, api_container_images_url, ContainerImage)
    end

    it "query Currencies" do
      FactoryBot.create(:currency)
      test_collection_query(:currencies, api_currencies_url, Currency)
    end

    it "query Measures" do
      FactoryBot.create(:chargeback_rate_detail_measure)
      test_collection_query(:measures, api_measures_url, ChargebackRateDetailMeasure)
    end

    it "query Clusters" do
      FactoryBot.create(:ems_cluster)
      test_collection_query(:clusters, api_clusters_url, EmsCluster)
    end

    it "query CloudVolumes" do
      FactoryBot.create(:cloud_volume)
      test_collection_query(:cloud_volumes, api_cloud_volumes_url, CloudVolume)
    end

    it "query Conditions" do
      FactoryBot.create(:condition)
      test_collection_query(:conditions, api_conditions_url, Condition)
    end

    it "query Actions" do
      FactoryBot.create(:miq_action)
      test_collection_query(:actions, api_actions_url, MiqAction)
    end

    it "query Cloud Object Store Containers" do
      FactoryBot.create(:cloud_object_store_container)
      test_collection_query(:cloud_object_store_containers, api_cloud_object_store_containers_url, CloudObjectStoreContainer)
    end

    it "query Data Stores" do
      FactoryBot.create(:storage)
      test_collection_query(:data_stores, api_data_stores_url, Storage)
    end

    it "query Events" do
      FactoryBot.create(:miq_event_definition)
      test_collection_query(:events, api_events_url, MiqEventDefinition)
    end

    it "query Features" do
      FactoryBot.create(:miq_product_feature, :identifier => "vm_auditing")
      test_collection_query(:features, api_features_url, MiqProductFeature)
    end

    it "query Flavors" do
      FactoryBot.create(:flavor)
      test_collection_query(:flavors, api_flavors_url, Flavor)
    end

    it "query Groups" do
      expect(Tenant.exists?).to be_truthy
      @user.miq_groups << FactoryBot.create(:miq_group)
      api_basic_authorize collection_action_identifier(:groups, :read, :get)
      get api_groups_url, :params => { :expand => 'resources' }
      expect_query_result(:groups, MiqGroup.non_tenant_groups.count, MiqGroup.count)
      expect_result_resources_to_include_data('resources', 'id' => MiqGroup.non_tenant_groups.pluck(:id).collect(&:to_s))
    end

    it "query Hosts" do
      FactoryBot.create(:host)
      test_collection_query(:hosts, api_hosts_url, Host, :guid)
    end

    it "query Pictures" do
      FactoryBot.create(:picture)
      test_collection_query(:pictures, api_pictures_url, Picture)
    end

    it "query Policies" do
      FactoryBot.create(:miq_policy)
      test_collection_query(:policies, api_policies_url, MiqPolicy)
    end

    it "query Policy Actions" do
      FactoryBot.create(:miq_action)
      test_collection_query(:policy_actions, api_policy_actions_url, MiqAction)
    end

    it "query Policy Profiles" do
      FactoryBot.create(:miq_policy_set)
      test_collection_query(:policy_profiles, api_policy_profiles_url, MiqPolicySet)
    end

    it "query Providers" do
      FactoryBot.create(:ext_management_system)
      test_collection_query(:providers, api_providers_url, ExtManagementSystem, :guid)
    end

    it "query Provision Dialogs" do
      FactoryBot.create(:miq_dialog)
      test_collection_query(:provision_dialogs, api_provision_dialogs_url, MiqDialog)
    end

    it "query Provision Requests" do
      FactoryBot.create(:miq_provision_request, :source => template, :requester => @user)
      test_collection_query(:provision_requests, api_provision_requests_url, MiqProvisionRequest)
    end

    it "query Rates" do
      FactoryBot.build(:chargeback_rate_detail)
      test_collection_query(:rates, api_rates_url, ChargebackRateDetail)
    end

    it "query Regions" do
      FactoryBot.create(:miq_region)
      test_collection_query(:regions, api_regions_url, MiqRegion)
    end

    it "query Reports" do
      FactoryBot.create(:miq_report)
      test_collection_query(:reports, api_reports_url, MiqReport)
    end

    it "query Report Results" do
      FactoryBot.create(:miq_report_result, :miq_group => @user.current_group)
      test_collection_query(:results, api_results_url, MiqReportResult)
    end

    it "query Request Tasks" do
      FactoryBot.create(:miq_request_task)
      test_collection_query(:request_tasks, api_request_tasks_url, MiqRequestTask)
    end

    it "query Requests" do
      FactoryBot.create(:vm_migrate_request, :requester => @user)
      test_collection_query(:requests, api_requests_url, MiqRequest)
    end

    it "query Resource Pools" do
      FactoryBot.create(:resource_pool)
      test_collection_query(:resource_pools, api_resource_pools_url, ResourcePool)
    end

    it "query Roles" do
      FactoryBot.create(:miq_user_role)
      test_collection_query(:roles, api_roles_url, MiqUserRole)
    end

    it "query Security Groups" do
      FactoryBot.create(:security_group)
      test_collection_query(:security_groups, api_security_groups_url, SecurityGroup)
    end

    it "query Servers" do
      miq_server # create resource
      test_collection_query(:servers, api_servers_url, MiqServer, :guid)
    end

    it "query Service Catalogs" do
      FactoryBot.create(:service_template_catalog)
      test_collection_query(:service_catalogs, api_service_catalogs_url, ServiceTemplateCatalog)
    end

    it "query Service Dialogs" do
      FactoryBot.create(:dialog, :label => "ServiceDialog1")
      test_collection_query(:service_dialogs, api_service_dialogs_url, Dialog)
    end

    it "query Service Requests" do
      FactoryBot.create(:service_template_provision_request, :requester => @user)
      test_collection_query(:service_requests, api_service_requests_url, ServiceTemplateProvisionRequest)
    end

    it "query Service Templates" do
      FactoryBot.create(:service_template)
      test_collection_query(:service_templates, api_service_templates_url, ServiceTemplate, :guid)
    end

    it "query Services" do
      FactoryBot.create(:service)
      test_collection_query(:services, api_services_url, Service)
    end

    it "query Tags" do
      FactoryBot.create(:classification_cost_center_with_tags)
      test_collection_query(:tags, api_tags_url, Tag)
    end

    it "query Tasks" do
      FactoryBot.create(:miq_task)
      test_collection_query(:tasks, api_tasks_url, MiqTask)
    end

    it "query Templates" do
      template # create resource
      test_collection_query(:templates, api_templates_url, MiqTemplate, :guid)
    end

    it "query Tenants" do
      api_basic_authorize "rbac_tenant_view"
      Tenant.seed
      test_collection_query(:tenants, api_tenants_url, Tenant)
    end

    it "query Users" do
      user = FactoryBot.create(:user)
      user.miq_groups << @user.current_group
      test_collection_query(:users, api_users_url, User)
    end

    it "query Vms" do
      FactoryBot.create(:vm_vmware)
      test_collection_query(:vms, api_vms_url, Vm, :guid)
    end

    it "query Zones" do
      FactoryBot.create(:zone, :name => "api zone")
      test_collection_query(:zones, api_zones_url, Zone)
    end

    it "query ContainerProjects" do
      FactoryBot.create(:container_project)
      test_collection_query(:container_projects, api_container_projects_url, ContainerProject)
    end

    it 'queries CloudNetworks' do
      FactoryBot.create(:cloud_network)
      test_collection_query(:cloud_networks, api_cloud_networks_url, CloudNetwork)
    end

    it 'queries CloudSubnets' do
      FactoryBot.create(:cloud_subnet)
      test_collection_query(:cloud_subnets, api_cloud_subnets_url, CloudSubnet)
    end

    it 'queries CloudTenants' do
      FactoryBot.create(:cloud_tenant)
      test_collection_query(:cloud_tenants, api_cloud_tenants_url, CloudTenant)
    end

    it 'query LoadBalancers' do
      FactoryBot.create(:load_balancer)
      test_collection_query(:load_balancers, api_load_balancers_url, LoadBalancer)
    end

    it 'query Alerts' do
      FactoryBot.create(:miq_alert_status)
      test_collection_query(:alerts, api_alerts_url, MiqAlertStatus)
    end

    it 'query Firmwares' do
      FactoryBot.create(:firmware)
      test_collection_query(:firmwares, api_firmwares_url, Firmware)
    end

    it 'query PhysicalSwitches' do
      FactoryBot.create(:physical_switch)
      test_collection_query(:physical_switches, api_physical_switches_url, PhysicalSwitch)
    end

    it 'query PhysicalServers' do
      FactoryBot.create(:physical_server)
      test_collection_query(:physical_servers, api_physical_servers_url, PhysicalServer)
    end

    it 'query CustomizationScripts' do
      FactoryBot.create(:customization_script)
      test_collection_query(:customization_scripts, api_customization_scripts_url, CustomizationScript)
    end

    it 'query GuestDevices' do
      FactoryBot.create(:guest_device)
      test_collection_query(:guest_devices, api_guest_devices_url, GuestDevice)
    end

    it 'query ContainerTemplates' do
      FactoryBot.create(:container_template)
      test_collection_query(:container_templates, api_container_templates_url, ContainerTemplate)
    end

    it 'query ContainerVolumes' do
      FactoryBot.create(:container_volume)
      test_collection_query(:container_volumes, api_container_volumes_url, ContainerVolume)
    end

    it 'query Switches' do
      FactoryBot.create(:switch)
      test_collection_query(:switches, api_switches_url, Switch)
    end

    it 'query OrchestrationStacks' do
      FactoryBot.create(:orchestration_stack)
      test_collection_query(:orchestration_stacks, api_orchestration_stacks_url, OrchestrationStack)
    end

    it 'query search MiqSearch' do
      FactoryBot.create(:miq_search)
      test_collection_query(:search_filters, api_search_filters_url, MiqSearch)
    end
  end

  context "Collections Bulk Queries" do
    it 'bulk query MiqAeDomain' do
      FactoryBot.create(:miq_ae_domain)
      test_collection_bulk_query(:automate_domains, api_automate_domains_url, MiqAeDomain)
    end

    it "bulk query Availability Zones" do
      FactoryBot.create(:availability_zone)
      test_collection_bulk_query(:availability_zones, api_availability_zones_url, AvailabilityZone)
    end

    it "bulk query Categories" do
      FactoryBot.create(:category)
      test_collection_bulk_query(:categories, api_categories_url, Category)
    end

    it "bulk query Chargebacks" do
      FactoryBot.create(:chargeback_rate)
      test_collection_bulk_query(:chargebacks, api_chargebacks_url, ChargebackRate)
    end

    it 'bulk query CloudNetworks' do
      FactoryBot.create(:cloud_network)
      test_collection_bulk_query(:cloud_networks, api_cloud_networks_url, CloudNetwork)
    end

    it "bulk query Clusters" do
      FactoryBot.create(:ems_cluster)
      test_collection_bulk_query(:clusters, api_clusters_url, EmsCluster)
    end

    it "bulk query Conditions" do
      FactoryBot.create(:condition)
      test_collection_bulk_query(:conditions, api_conditions_url, Condition)
    end

    it "bulk query Cloud Object Store Containers" do
      FactoryBot.create(:cloud_object_store_container)
      test_collection_bulk_query(:cloud_object_store_containers, api_cloud_object_store_containers_url, CloudObjectStoreContainer)
    end

    it "bulk query Actions" do
      FactoryBot.create(:miq_action)
      test_collection_bulk_query(:actions, api_actions_url, MiqAction)
    end

    it "bulk query ContainerGroups" do
      FactoryBot.create(:container_group)
      test_collection_bulk_query(:container_groups, api_container_groups_url, ContainerGroup)
    end

    it "bulk query Data Stores" do
      FactoryBot.create(:storage)
      test_collection_bulk_query(:data_stores, api_data_stores_url, Storage)
    end

    it "bulk query Events" do
      FactoryBot.create(:miq_event_definition)
      test_collection_bulk_query(:events, api_events_url, MiqEventDefinition)
    end

    it "bulk query Flavors" do
      FactoryBot.create(:flavor)
      test_collection_bulk_query(:flavors, api_flavors_url, Flavor)
    end

    it "bulk query FloatingIps" do
      FactoryBot.create(:floating_ip)
      test_collection_bulk_query(:floating_ips, api_floating_ips_url, FloatingIp)
    end

    it "bulk query Groups" do
      group = FactoryBot.create(:miq_group)
      @user.miq_groups << group
      test_collection_bulk_query(:groups, api_groups_url, MiqGroup, group.id)
    end

    it "bulk query Hosts" do
      FactoryBot.create(:host)
      test_collection_bulk_query(:hosts, api_hosts_url, Host)
    end

    it 'bulk query NetworkRouters' do
      FactoryBot.create(:network_router)
      test_collection_bulk_query(:network_routers, api_network_routers_url, NetworkRouter)
    end

    it "bulk query Policies" do
      FactoryBot.create(:miq_policy)
      test_collection_bulk_query(:policies, api_policies_url, MiqPolicy)
    end

    it "bulk query Policy Actions" do
      FactoryBot.create(:miq_action)
      test_collection_bulk_query(:policy_actions, api_policy_actions_url, MiqAction)
    end

    it "bulk query Policy Profiles" do
      FactoryBot.create(:miq_policy_set)
      test_collection_bulk_query(:policy_profiles, api_policy_profiles_url, MiqPolicySet)
    end

    it "bulk query Providers" do
      FactoryBot.create(:ext_management_system)
      test_collection_bulk_query(:providers, api_providers_url, ExtManagementSystem)
    end

    it "bulk query Provision Dialogs" do
      FactoryBot.create(:miq_dialog)
      test_collection_bulk_query(:provision_dialogs, api_provision_dialogs_url, MiqDialog)
    end

    it "bulk query Provision Requests" do
      FactoryBot.create(:miq_provision_request, :source => template, :requester => @user)
      test_collection_bulk_query(:provision_requests, api_provision_requests_url, MiqProvisionRequest)
    end

    it "bulk query Rates" do
      FactoryBot.create(:chargeback_rate_detail, :chargeable_field => FactoryBot.build(:chargeable_field))
      test_collection_bulk_query(:rates, api_rates_url, ChargebackRateDetail)
    end

    it "bulk query Regions" do
      FactoryBot.create(:miq_region)
      test_collection_bulk_query(:regions, api_regions_url, MiqRegion)
    end

    it "bulk query Report Results" do
      FactoryBot.create(:miq_report_result, :miq_group => @user.current_group)
      test_collection_bulk_query(:results, api_results_url, MiqReportResult)
    end

    it "bulk query Requests" do
      FactoryBot.create(:vm_migrate_request, :requester => @user)
      test_collection_bulk_query(:requests, api_requests_url, MiqRequest)
    end

    it "bulk query Resource Pools" do
      FactoryBot.create(:resource_pool)
      test_collection_bulk_query(:resource_pools, api_resource_pools_url, ResourcePool)
    end

    it "bulk query Roles" do
      FactoryBot.create(:miq_user_role)
      test_collection_bulk_query(:roles, api_roles_url, MiqUserRole)
    end

    it "bulk query Security Groups" do
      FactoryBot.create(:security_group)
      test_collection_bulk_query(:security_groups, api_security_groups_url, SecurityGroup)
    end

    it "bulk query Service Catalogs" do
      FactoryBot.create(:service_template_catalog)
      test_collection_bulk_query(:service_catalogs, api_service_catalogs_url, ServiceTemplateCatalog)
    end

    it "bulk query Service Dialogs" do
      FactoryBot.create(:dialog, :label => "ServiceDialog1")
      test_collection_bulk_query(:service_dialogs, api_service_dialogs_url, Dialog)
    end

    it "bulk query Service Orders" do
      FactoryBot.create(:service_order, :user => @user)
      test_collection_bulk_query(:service_orders, api_service_orders_url, ServiceOrder)
    end

    it "bulk query Service Requests" do
      FactoryBot.create(:service_template_provision_request, :requester => @user)
      test_collection_bulk_query(:service_requests, api_service_requests_url, ServiceTemplateProvisionRequest)
    end

    it "bulk query Service Templates" do
      FactoryBot.create(:service_template)
      test_collection_bulk_query(:service_templates, api_service_templates_url, ServiceTemplate)
    end

    it "bulk query Services" do
      FactoryBot.create(:service)
      test_collection_bulk_query(:services, api_services_url, Service)
    end

    it "bulk query Tags" do
      FactoryBot.create(:classification_cost_center_with_tags)
      test_collection_bulk_query(:tags, api_tags_url, Tag)
    end

    it "bulk query Tasks" do
      FactoryBot.create(:miq_task)
      test_collection_bulk_query(:tasks, api_tasks_url, MiqTask)
    end

    it "bulk query Templates" do
      template # create resource
      test_collection_bulk_query(:templates, api_templates_url, MiqTemplate)
    end

    it "bulk query Tenants" do
      api_basic_authorize "rbac_tenant_view"
      Tenant.seed
      test_collection_bulk_query(:tenants, api_tenants_url, Tenant)
    end

    it "bulk query Users" do
      FactoryBot.create(:user)
      test_collection_bulk_query(:users, api_users_url, User)
    end

    it "bulk query Vms" do
      FactoryBot.create(:vm_vmware)
      test_collection_bulk_query(:vms, api_vms_url, Vm)
    end

    it "doing a bulk query renders actions for which the user is authorized" do
      vm = FactoryBot.create(:vm_vmware)
      api_basic_authorize(collection_action_identifier(:vms, :query), action_identifier(:vms, :start))

      # HMMM
      post(api_vms_url, :params => gen_request(:query, [{"id" => vm.id}]))

      expected = {
        "results" => [
          a_hash_including(
            "actions" => [
              a_hash_including(
                "name"   => "start",
                "method" => "post",
                "href"   => api_vm_url(nil, vm)
              )
            ]
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
    end

    it "bulk query Vms with invalid guid fails" do
      FactoryBot.create(:vm_vmware)
      api_basic_authorize collection_action_identifier(:vms, :query)

      post(api_vms_url, :params => gen_request(:query, [{"guid" => "B999999D"}]))

      expect(response.parsed_body).to include_error_with_message("Invalid vms resource specified - guid=B999999D")
      expect(response).to have_http_status(:not_found)
    end

    it "bulk query Zones" do
      FactoryBot.create(:zone, :name => "api zone")
      test_collection_bulk_query(:zones, api_zones_url, Zone)
    end

    it 'bulk query LoadBalancers' do
      FactoryBot.create(:load_balancer)
      test_collection_bulk_query(:load_balancers, api_load_balancers_url, LoadBalancer)
    end

    it "bulk query CloudSubnets" do
      FactoryBot.create(:cloud_subnet)
      test_collection_bulk_query(:cloud_subnets, api_cloud_subnets_url, CloudSubnet)
    end

    it 'bulk query CloudTenants' do
      FactoryBot.create(:cloud_tenant)
      test_collection_bulk_query(:cloud_tenants, api_cloud_tenants_url, CloudTenant)
    end

    it 'bulk query CloudVolumes' do
      FactoryBot.create(:cloud_volume)
      test_collection_bulk_query(:cloud_volumes, api_cloud_volumes_url, CloudVolume)
    end

    it 'bulk query Container' do
      FactoryBot.create(:container)
      test_collection_bulk_query(:containers, api_containers_url, Container)
    end

    it 'bulk query Firmwares' do
      FactoryBot.create(:firmware)
      test_collection_bulk_query(:firmwares, api_firmwares_url, Firmware)
    end

    it 'bulk query PhysicalSwitches' do
      FactoryBot.create(:physical_switch)
      test_collection_bulk_query(:physical_switches, api_physical_switches_url, PhysicalSwitch)
    end

    it 'bulk query PhysicalServers' do
      FactoryBot.create(:physical_server)
      test_collection_bulk_query(:physical_servers, api_physical_servers_url, PhysicalServer)
    end

    it 'bulk query CustomizationScripts' do
      FactoryBot.create(:customization_script)
      test_collection_bulk_query(:customization_scripts, api_customization_scripts_url, CustomizationScript)
    end

    it 'bulk query GuestDevices' do
      FactoryBot.create(:guest_device)
      test_collection_bulk_query(:guest_devices, api_guest_devices_url, GuestDevice)
    end

    it 'bulk query container nodes' do
      FactoryBot.create(:container_node)
      test_collection_bulk_query(:container_nodes, api_container_nodes_url, ContainerNode)
    end

    it 'bulk query cloud templates' do
      FactoryBot.create(:template_cloud)
      test_collection_bulk_query(:cloud_templates, api_cloud_templates_url, ManageIQ::Providers::CloudManager::Template)
    end

    it 'bulk query container_projects' do
      FactoryBot.create(:container_project)
      test_collection_bulk_query(:container_projects, api_container_projects_url, ContainerProject)
    end

    it 'bulk query container templates' do
      FactoryBot.create(:container_template)
      test_collection_bulk_query(:container_templates, api_container_templates_url, ContainerTemplate)
    end

    it 'bulk query container volumes' do
      FactoryBot.create(:container_volume)
      test_collection_bulk_query(:container_volumes, api_container_volumes_url, ContainerVolume)
    end

    it 'bulk query switches' do
      FactoryBot.create(:switch)
      test_collection_bulk_query(:switches, api_switches_url, Switch)
    end

    it 'bulk query orchestration stacks' do
      FactoryBot.create(:orchestration_stack)
      test_collection_bulk_query(:orchestration_stacks, api_orchestration_stacks_url, OrchestrationStack)
    end

    it 'bulk query search filters' do
      FactoryBot.create(:miq_search)
      test_collection_bulk_query(:search_filters, api_search_filters_url, MiqSearch)
    end
  end
end
