#
# Rest API Request Tests - Providers specs
#
# - Creating a provider                   /api/providers                        POST
# - Creating a provider via action        /api/providers                        action "create"
# - Creating multiple providers           /api/providers                        action "create"
# - Edit a provider                       /api/providers/:id                    action "edit"
# - Edit multiple providers               /api/providers                        action "edit"
# - Delete a provider                     /api/providers/:id                    DELETE
# - Delete a provider by action           /api/providers/:id                    action "delete"
# - Delete multiple providers             /api/providers                        action "delete"
#
# - Refresh a provider                    /api/providers/:id                    action "refresh"
# - Refresh multiple providers            /api/providers                        action "refresh"
#
describe "Providers API" do
  ENDPOINT_ATTRS = Api::ProvidersController::ENDPOINT_ATTRS
  CREDENTIALS_ATTR = Api::ProvidersController::CREDENTIALS_ATTR

  let(:default_credentials) { {"userid" => "admin1", "password" => "password1"} }
  let(:metrics_credentials) { {"userid" => "admin2", "password" => "password2", "auth_type" => "metrics"} }
  let(:compound_credentials) { [default_credentials, metrics_credentials] }
  let(:containers_credentials) do
    {
      "auth_type" => "bearer",
      "auth_key"  => SecureRandom.hex
    }
  end
  let(:certificate_authority) do
    # openssl req -x509 -newkey rsa:512 -out cert.pem -nodes, all defaults, twice
    <<-EOPEM.strip_heredoc
      -----BEGIN CERTIFICATE-----
      MIIBzTCCAXegAwIBAgIJAOgErvCo3YfDMA0GCSqGSIb3DQEBCwUAMEIxCzAJBgNV
      BAYTAlhYMRUwEwYDVQQHDAxEZWZhdWx0IENpdHkxHDAaBgNVBAoME0RlZmF1bHQg
      Q29tcGFueSBMdGQwHhcNMTcwMTE3MTUzODUxWhcNMTcwMjE2MTUzODUxWjBCMQsw
      CQYDVQQGEwJYWDEVMBMGA1UEBwwMRGVmYXVsdCBDaXR5MRwwGgYDVQQKDBNEZWZh
      dWx0IENvbXBhbnkgTHRkMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAKkV4c0cV0oB
      7e1hMmQygmqEELooktNhMpnqqUyy2Lbi/QI3v9f4jyVrI0Uq3x+FXAlopj2ZE+Zp
      qiaq6vmlPSECAwEAAaNQME4wHQYDVR0OBBYEFN6XWVKCGYdjnecoVEt7rtNP4d6S
      MB8GA1UdIwQYMBaAFN6XWVKCGYdjnecoVEt7rtNP4d6SMAwGA1UdEwQFMAMBAf8w
      DQYJKoZIhvcNAQELBQADQQB1IY8KIHcESeKuS8C1i5/wPuFNP3L2a5XKJ29IQsJy
      xY9wgnq7LoIesQsiuiXOGa8L8C9CviIV38Wz9ySt3aLZ
      -----END CERTIFICATE-----
    EOPEM
  end

  let(:sample_vmware) do
    {
      "type"        => "ManageIQ::Providers::Vmware::InfraManager",
      "name"        => "sample vmware",
      "hostname"    => "sample-vmware.provider.com",
      "ipaddress"   => "100.200.300.1",
      "credentials" => {
        "userid"   => "uname",
        "password" => "pword"
      }
    }
  end
  let(:sample_rhevm) do
    {
      "type"                  => "ManageIQ::Providers::Redhat::InfraManager",
      "name"                  => "sample rhevm",
      "port"                  => 5000,
      "hostname"              => "sample-rhevm.provider.com",
      "ipaddress"             => "100.200.300.2",
      "security_protocol"     => "kerberos",
      "certificate_authority" => certificate_authority,
      "credentials"           => {
        "userid"   => "uname",
        "password" => "pword"
      }
    }
  end

  CONTAINERS_CLASSES = {
    "Kubernetes"          => "ManageIQ::Providers::Kubernetes::ContainerManager",
    "Openshift"           => "ManageIQ::Providers::Openshift::ContainerManager",
  }.freeze
  let(:sample_containers) do
    {
      "type"                  => containers_class,
      "name"                  => "sample openshift",
      "port"                  => 18_443,
      "hostname"              => "sample-openshift.provider.com",
      "ipaddress"             => "100.200.300.3",
      "security_protocol"     => "ssl-without-validation",
      "certificate_authority" => certificate_authority,
    }
  end
  let(:default_connection) do
    {
      "endpoint"       => {
        "role"                  => "default",
        "hostname"              => "sample-openshift-multi-end-point.provider.com",
        "port"                  => 18_443,
        "security_protocol"     => "ssl-without-validation",
        "certificate_authority" => certificate_authority,
      },
      "authentication" => {
        "role"     => "bearer",
        "auth_key" => SecureRandom.hex
      }
    }
  end
  let(:updated_connection) do
    {
      "endpoint"       => {
        "role"                  => "default",
        "hostname"              => "sample-openshift-multi-end-point.provider.com",
        "port"                  => "28443",
        "security_protocol"     => "ssl-without-validation",
        "certificate_authority" => certificate_authority,
      },
      "authentication" => {
        "role"     => "bearer",
        "auth_key" => SecureRandom.hex
      }
    }
  end
  let(:hawkular_connection) do
    {
      "endpoint"       => {
        "role"                  => "hawkular",
        "hostname"              => "sample-openshift-multi-end-point.provider.com",
        "port"                  => 1_443,
        "security_protocol"     => "ssl-without-validation",
        "certificate_authority" => certificate_authority,
      },
      "authentication" => {
        "role"     => "hawkular",
        "auth_key" => SecureRandom.hex
      }
    }
  end
  let(:prometheus_connection) do
    {
      "endpoint"       => {
        "role"              => "prometheus",
        "hostname"          => "prometheus.example.com",
        "port"              => 443,
        "security_protocol" => "ssl-without-validation"
      },
      "authentication" => {
        "role"     => "prometheus",
        "auth_key" => SecureRandom.hex
      }
    }
  end
  let(:prometheus_alerts_connection) do
    {
      "endpoint"       => {
        "role"              => "prometheus_alerts",
        "hostname"          => "prometheus.example.com",
        "port"              => 443,
        "security_protocol" => "ssl-without-validation"
      },
      "authentication" => {
        "role"     => "prometheus_alerts",
        "auth_key" => SecureRandom.hex
      }
    }
  end
  let(:sample_containers_multi_end_point_with_hawkular) do
    {
      "type"                      => containers_class,
      "name"                      => "sample containers provider with multiple endpoints and hawkular",
      "connection_configurations" => [default_connection, hawkular_connection]
    }
  end
  let(:sample_containers_multi_end_point_with_prometheus) do
    {
      "type"                      => containers_class,
      "name"                      => "sample containers provider with multiple endpoints and prometheus",
      "connection_configurations" => [prometheus_alerts_connection, default_connection, prometheus_connection]
    }
  end

  let(:sample_amazon) do
    {
      "type"        => "ManageIQ::Providers::Amazon::CloudManager",
      "name"        => "sample amazon",
      "hostname"    => "sample-amazon.provider.com",
      "ipaddress"   => "100.200.300.4",
      "credentials" => {
        "userid"   => "uname",
        "password" => "pword"
      }
    }
  end

  def have_endpoint_attributes(expected_hash)
    h = expected_hash.slice(*ENDPOINT_ATTRS)
    h["port"] = h["port"].to_i if h.key?("port")
    have_attributes(h)
  end

  context 'Provider\'s virtual attributes(= direct or indirect associations) with RBAC' do
    let(:ems_openstack)  { FactoryBot.create(:ems_openstack, :tenant_mapping_enabled => true) }
    let(:ems_cinder)     { ManageIQ::Providers::StorageManager::CinderManager.find_by(:parent_manager => ems_openstack) }
    let(:ems_cinder_url) { api_provider_url(nil, ems_cinder) }

    let(:tenant) { FactoryBot.create(:tenant, :source_type => 'CloudTenant') }
    let!(:cloud_tenant_1) { FactoryBot.create(:cloud_tenant, :source_tenant => tenant, :ext_management_system => ems_openstack) }
    let!(:cloud_tenant_2) { FactoryBot.create(:cloud_tenant, :source_tenant => Tenant.root_tenant, :ext_management_system => ems_openstack) }

    let(:role)   { FactoryBot.create(:miq_user_role) }
    let!(:group) { FactoryBot.create(:miq_group, :tenant => tenant, :miq_user_role => role) }
    let!(:vm)    { FactoryBot.create(:vm_openstack, :ext_management_system => ems_cinder, :miq_group => group) }
    let!(:vm_1)  { FactoryBot.create(:vm_openstack, :ext_management_system => ems_cinder) }

    context 'with restricted user' do
      before do
        @user.update(:miq_groups => [group])
        @role = role
      end

      it 'lists only CloudTenant for the restricted user(indirect association)' do
        api_basic_authorize action_identifier(:providers, :read, :resource_actions, :get)
        get(ems_cinder_url, :params => { :attributes => 'parent_manager.cloud_tenants' })
        cloud_tenant_ids = response.parsed_body['parent_manager']['cloud_tenants'].map { |x| x['id'] }
        expect([cloud_tenant_1.id.to_s]).to match_array(cloud_tenant_ids)
      end

      it 'lists only CloudTenant for the restricted user(direct association)' do
        api_basic_authorize action_identifier(:providers, :read, :resource_actions, :get)
        get(ems_cinder_url, :params => { :attributes => 'vms' })
        vm_ids = response.parsed_body['vms'].map { |x| x['id'] }
        expect([vm.id.to_s]).to match_array(vm_ids)
      end
    end

    it 'lists all CloudTenants' do
      api_basic_authorize action_identifier(:providers, :read, :resource_actions, :get)
      get(ems_cinder_url, :params => { :attributes => 'parent_manager.cloud_tenants' })
      cloud_tenant_ids = response.parsed_body['parent_manager']['cloud_tenants'].map { |x| x['id'] }
      expect([cloud_tenant_1.id.to_s, cloud_tenant_2.id.to_s]).to match_array(cloud_tenant_ids)
    end
  end

  context "Provider custom_attributes" do
    let(:provider) { FactoryBot.create(:ems_redhat_v4, sample_rhevm.except("credentials")) }
    let(:provider_url) { api_provider_url(nil, provider) }
    let(:ca1) { FactoryBot.create(:custom_attribute, :name => "name1", :value => "value1") }
    let(:ca2) { FactoryBot.create(:custom_attribute, :name => "name2", :value => "value2") }
    let(:provider_ca_url) { api_provider_custom_attributes_url(nil, provider) }
    let(:ca1_url) { api_provider_custom_attribute_url(nil, provider, ca1) }
    let(:ca2_url) { api_provider_custom_attribute_url(nil, provider, ca2) }
    let(:provider_ca_url_list) { [ca1_url, ca2_url] }

    it "getting custom_attributes from a provider with no custom_attributes" do
      api_basic_authorize

      get(provider_ca_url)

      expect_empty_query_result(:custom_attributes)
    end

    it "getting custom_attributes from a provider" do
      api_basic_authorize
      provider.custom_attributes = [ca1, ca2]

      get provider_ca_url

      expect_query_result(:custom_attributes, 2)

      expect_result_resources_to_include_hrefs("resources",
                                               [api_provider_custom_attribute_url(nil, provider, ca1),
                                                api_provider_custom_attribute_url(nil, provider, ca2)])
    end

    it "getting custom_attributes from a provider in expanded form" do
      api_basic_authorize
      provider.custom_attributes = [ca1, ca2]

      get provider_ca_url, :params => { :expand => "resources" }

      expect_query_result(:custom_attributes, 2)

      expect_result_resources_to_include_data("resources", "name" => %w(name1 name2))
    end

    it "getting custom_attributes from a provider using expand" do
      api_basic_authorize action_identifier(:providers, :read, :resource_actions, :get)
      provider.custom_attributes = [ca1, ca2]

      get provider_url, :params => { :expand => "custom_attributes" }

      expect_single_resource_query("guid" => provider.guid)

      expect_result_resources_to_include_data("custom_attributes", "name" => %w(name1 name2))
    end

    it "delete a custom_attribute without appropriate role" do
      api_basic_authorize
      provider.custom_attributes = [ca1]

      post(provider_ca_url, :params => gen_request(:delete, nil, provider_url))

      expect(response).to have_http_status(:forbidden)
    end

    it "delete a custom_attribute from a provider via the delete action" do
      api_basic_authorize action_identifier(:providers, :edit)
      provider.custom_attributes = [ca1]

      post(provider_ca_url, :params => gen_request(:delete, nil, ca1_url))

      expect(response).to have_http_status(:ok)

      expect(provider.reload.custom_attributes).to be_empty
    end

    it "add custom attribute to a provider without a name" do
      api_basic_authorize action_identifier(:providers, :edit)

      post(provider_ca_url, :params => gen_request(:add, "value" => "value1"))

      expect_bad_request("Must specify a name")
    end

    it "prevents adding custom attribute to a provider with forbidden section" do
      api_basic_authorize action_identifier(:providers, :edit)

      post(provider_ca_url, :params => gen_request(:add, [{"name" => "name3", "value" => "value3",
                                                    "section" => "bad_section"}]))

      expect_bad_request("Could not add custom attributes - Invalid attribute section specified: bad_section")
    end

    it "add custom attributes to a provider" do
      api_basic_authorize action_identifier(:providers, :edit)

      post(provider_ca_url, :params => gen_request(:add, [{"name" => "name1", "value" => "value1"},
                                                          {"name" => "name2", "value" => "value2", "section" => "metadata"}]))
      expected = {
        "results" => a_collection_containing_exactly(
          a_hash_including("name" => "name1", "value" => "value1", "section" => "metadata"),
          a_hash_including("name" => "name2", "value" => "value2", "section" => "metadata")
        )
      }
      expect(response).to have_http_status(:ok)

      expect(response.parsed_body).to include(expected)

      expect(provider.custom_attributes.size).to eq(2)
    end

    it "formats custom attribute of type date" do
      api_basic_authorize action_identifier(:providers, :edit)
      date_field = DateTime.new.in_time_zone

      post(provider_ca_url, :params => gen_request(:add, [{"name"       => "name1",
                                                           "value"      => date_field,
                                                           "field_type" => "DateTime"}]))

      expect(response).to have_http_status(:ok)

      expect(provider.custom_attributes.first.serialized_value).to eq(date_field)

      expect(provider.custom_attributes.first.section).to eq("metadata")
    end

    it "edit a custom attribute by name" do
      api_basic_authorize action_identifier(:providers, :edit)
      provider.custom_attributes = [ca1]

      post(provider_ca_url, :params => gen_request(:edit, "name" => "name1", "value" => "value one"))

      expect(response).to have_http_status(:ok)

      expect_result_resources_to_include_data("results", "value" => ["value one"])

      expect(provider.reload.custom_attributes.first.value).to eq("value one")
    end
  end

  describe "Providers actions on Provider class" do
    let(:foreman_type) { ManageIQ::Providers::Foreman::Provider }
    let(:sample_foreman) do
      {
        :name        => 'my-foreman',
        :type        => foreman_type.to_s,
        :credentials => {:userid => 'admin', :password => 'changeme'},
        :url         => 'https://foreman.example.com'
      }
    end

    it "rejects requests with invalid provider_class" do
      api_basic_authorize(action_identifier(:providers, :read, :collection_actions, :get))

      get api_providers_url, :params => { :provider_class => "bad_class" }

      expect_bad_request(/unsupported/i)
    end

    it "requires credentials if no connection_configurations are specified" do
      api_basic_authorize collection_action_identifier(:providers, :create)

      post(api_providers_url, :params => gen_request(:create, [{"name" => "name3"}]))

      expect_bad_request("Must specify credentials")
    end

    it "supports requests with valid provider_class" do
      api_basic_authorize collection_action_identifier(:providers, :read, :get)

      FactoryBot.build(:provider_foreman)
      get api_providers_url, :params => { :provider_class => "provider", :expand => "resources" }

      klass = Provider
      expect_query_result(:providers, klass.count, klass.count)
      expect_result_resources_to_include_data("resources", "name" => klass.pluck(:name))
    end

    it 'creates valid foreman provider' do
      api_basic_authorize collection_action_classed_identifier(:providers, :create, :post, "Provider")

      post(api_providers_url + '?provider_class=provider', :params => gen_request(:create, sample_foreman))

      expect(response).to have_http_status(:ok)

      provider_id = response.parsed_body["results"].first["id"]
      provider = foreman_type.find(provider_id)
      [:name, :type, :url].each do |item|
        expect(provider.send(item)).to eq(sample_foreman[item])
      end
    end

    it 'returns the correct href reference on the collection' do
      provider = FactoryBot.create(:provider_foreman)
      api_basic_authorize collection_action_identifier(:providers, :read, :get)

      get api_providers_url, :params => { :provider_class => 'provider' }

      expected = {
        'resources' => [{'href' => "#{api_provider_url(nil, provider)}?provider_class=provider"}],
        'actions'   => a_collection_including(
          a_hash_including('href' => a_string_including('?provider_class=provider'))
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'returns the correct href reference on a resource' do
      provider = FactoryBot.create(:provider_foreman)
      api_basic_authorize action_identifier(:providers, :read, :resource_actions, :get),
                          action_identifier(:providers, :edit)

      get api_provider_url(nil, provider), :params => { :provider_class => :provider }

      expected = {
        'href'    => "#{api_provider_url(nil, provider)}?provider_class=provider",
        'actions' => a_collection_including(
          a_hash_including('href' => "#{api_provider_url(nil, provider)}?provider_class=provider")
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Providers create" do
    before(:each) do
      require "ovirtsdk4" # incase it hasn't been autoloaded yet

      allow(OvirtSDK4::Probe).to receive(:probe)
        .and_return([OvirtSDK4::ProbeResult.new(:version => '3')])
    end

    it 'allows provider specific attributes to be specified' do
      allow(ManageIQ::Providers::Azure::CloudManager).to receive(:api_allowed_attributes).and_return(%w(azure_tenant_id))
      tenant = FactoryBot.create(:cloud_tenant)
      api_basic_authorize collection_action_classed_identifier(:providers, :create, :post, "ManageIQ::Providers::CloudManager")

      post(api_providers_url, :params => { "type"            => "ManageIQ::Providers::Azure::CloudManager",
                                           "name"            => "sample azure provider",
                                           "hostname"        => "hostname",
                                           "zone"            => @zone,
                                           "azure_tenant_id" => tenant.id,
                                           "credentials"     => {}})

      expected = {
        "results" => [a_hash_including("uid_ems" => tenant.id.to_s, "name" => "sample azure provider")]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "rejects creation without appropriate role" do
      api_basic_authorize

      post(api_providers_url, :params => sample_rhevm)

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects provider creation with id specified" do
      api_basic_authorize collection_action_identifier(:providers, :create)

      post(api_providers_url, :params => { "name" => "sample provider", "id" => 100 })

      expect_bad_request(/id or href should not be specified/i)
    end

    it "rejects provider creation with invalid type specified" do
      api_basic_authorize collection_action_identifier(:providers, :create)

      post(api_providers_url, :params => { "name" => "sample provider", "type" => "BogusType", "credentials" => {} })

      expect_bad_request(/Invalid provider type BogusType/i)
    end

    it "supports single provider creation" do
      api_basic_authorize collection_action_classed_identifier(:providers, :create, :post, "ManageIQ::Providers::InfraManager")

      post(api_providers_url, :params => sample_rhevm)

      expect(response).to have_http_status(:ok)
      expected = {
        "results" => [
          a_hash_including({"id" => kind_of(String)}.merge(sample_rhevm.except(*ENDPOINT_ATTRS, CREDENTIALS_ATTR)))
        ]
      }
      expect(response.parsed_body).to include(expected)

      provider_id = response.parsed_body["results"].first["id"]
      endpoint = ExtManagementSystem.find(provider_id).default_endpoint
      expect(endpoint).to have_endpoint_attributes(sample_rhevm)
    end

    CONTAINERS_CLASSES.each do |name, klass|
      context name do
        let(:containers_class) { klass }

        it "supports creation with auth_key specified" do
          api_basic_authorize collection_action_classed_identifier(:providers, :create, :post, "ManageIQ::Providers::ContainerManager")

          post(api_providers_url, :params => sample_containers.merge("credentials" => [containers_credentials]))

          expect(response).to have_http_status(:ok)
          expected = {
            "results" => [
              a_hash_including({"id" => kind_of(String)}.merge(sample_containers.except(*ENDPOINT_ATTRS, CREDENTIALS_ATTR)))
            ]
          }
          expect(response.parsed_body).to include(expected)

          provider_id = response.parsed_body["results"].first["id"]
          ems = ExtManagementSystem.find(provider_id)
          expect(ems.authentications.size).to eq(1)
          expect(ems).to have_endpoint_attributes(sample_containers)
        end
      end
    end

    it "supports single provider creation via action" do
      api_basic_authorize collection_action_classed_identifier(:providers, :create, :post, "ManageIQ::Providers::InfraManager")

      post(api_providers_url, :params => gen_request(:create, sample_rhevm))

      expect(response).to have_http_status(:ok)
      expected = {
        "results" => [
          a_hash_including({"id" => kind_of(String)}.merge(sample_rhevm.except(*ENDPOINT_ATTRS, CREDENTIALS_ATTR)))
        ]
      }
      expect(response.parsed_body).to include(expected)

      provider_id = response.parsed_body["results"].first["id"]
      expect(ExtManagementSystem.exists?(provider_id)).to be_truthy
    end

    it "should fail single provider creation via action" do
      api_basic_authorize collection_action_classed_identifier(:providers, :create, :post, "ManageIQ::Providers::CloudManager")

      post(api_providers_url, :params => gen_request(:create, sample_rhevm))

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to include_error_with_message("Create action is forbidden for ManageIQ::Providers::Redhat::InfraManager requests")
    end

    it "supports single provider creation with simple credentials" do
      api_basic_authorize collection_action_classed_identifier(:providers, :create, :post, "ManageIQ::Providers::InfraManager")

      post(api_providers_url, :params => sample_vmware.merge("credentials" => default_credentials))

      expect(response).to have_http_status(:ok)
      expected = {
        "results" => [
          a_hash_including({"id" => kind_of(String)}.merge(sample_vmware.except(*ENDPOINT_ATTRS, CREDENTIALS_ATTR)))
        ]
      }
      expect(response.parsed_body).to include(expected)

      provider_id = response.parsed_body["results"].first["id"]
      provider = ExtManagementSystem.find(provider_id)
      expect(provider.authentication_userid).to eq(default_credentials["userid"])
      expect(provider.authentication_password).to eq(default_credentials["password"])
    end

    it "supports single provider creation with compound credentials" do
      api_basic_authorize collection_action_classed_identifier(:providers, :create, :post, "ManageIQ::Providers::InfraManager")

      post(api_providers_url, :params => sample_rhevm.merge("credentials" => compound_credentials))

      expect(response).to have_http_status(:ok)
      expected = {
        "results" => [
          a_hash_including({"id" => kind_of(String)}.merge(sample_rhevm.except(*ENDPOINT_ATTRS, CREDENTIALS_ATTR)))
        ]
      }
      expect(response.parsed_body).to include(expected)

      provider_id = response.parsed_body["results"].first["id"]
      provider = ExtManagementSystem.find(provider_id)
      expect(provider.authentication_userid(:default)).to eq(default_credentials["userid"])
      expect(provider.authentication_password(:default)).to eq(default_credentials["password"])
      expect(provider.authentication_userid(:metrics)).to eq(metrics_credentials["userid"])
      expect(provider.authentication_password(:metrics)).to eq(metrics_credentials["password"])
    end

    it "supports multiple provider creation" do
      api_basic_authorize collection_action_classed_identifier(:providers, :create, :post, "ManageIQ::Providers::InfraManager")

      post(api_providers_url, :params => gen_request(:create, [sample_vmware, sample_rhevm]))

      expect(response).to have_http_status(:ok)
      expected = {
        "results" => a_collection_containing_exactly(
          a_hash_including({"id" => kind_of(String)}.merge(sample_vmware.except(*ENDPOINT_ATTRS, CREDENTIALS_ATTR))),
          a_hash_including({"id" => kind_of(String)}.merge(sample_rhevm.except(*ENDPOINT_ATTRS, CREDENTIALS_ATTR)))
        )
      }
      expect(response.parsed_body).to include(expected)

      results = response.parsed_body["results"]
      p1_id = results.first["id"]
      p2_id = results.second["id"]
      expect(ExtManagementSystem.exists?(p1_id)).to be_truthy
      expect(ExtManagementSystem.exists?(p2_id)).to be_truthy
    end

    CONTAINERS_CLASSES.each do |name, klass|
      context name do
        let(:containers_class) { klass }

        def token(connection)
          connection["authentication"]["auth_key"]
        end

        it "supports provider with multiple endpoints creation with hawkular" do
          api_basic_authorize collection_action_classed_identifier(:providers, :create, :post, "ManageIQ::Providers::ContainerManager")

          post(api_providers_url, :params => gen_request(:create, sample_containers_multi_end_point_with_hawkular))

          expect(response).to have_http_status(:ok)
          expected = {"id"   => a_kind_of(String),
                      "type" => containers_class,
                      "name" => "sample containers provider with multiple endpoints and hawkular"}

          results = response.parsed_body["results"]
          expect(results.first).to include(expected)

          provider_id = results.first["id"]
          provider = ExtManagementSystem.find(provider_id)
          expect(provider).to have_endpoint_attributes(default_connection["endpoint"])
          expect(provider.authentication_token).to eq(token(default_connection))

          expect(provider.connection_configurations.hawkular.endpoint).to have_endpoint_attributes(
            hawkular_connection["endpoint"]
          )
          expect(provider.authentication_token(:hawkular)).to eq(token(hawkular_connection))
        end

        it "supports provider with multiple endpoints creation and prometheus" do
          api_basic_authorize collection_action_classed_identifier(:providers, :create, :post, "ManageIQ::Providers::ContainerManager")

          post(api_providers_url, :params => gen_request(:create, sample_containers_multi_end_point_with_prometheus))

          expect(response).to have_http_status(:ok)
          expected = {"id"   => a_kind_of(String),
                      "type" => containers_class,
                      "name" => "sample containers provider with multiple endpoints and prometheus"}

          results = response.parsed_body["results"]
          expect(results.first).to include(expected)

          provider_id = results.first["id"]
          provider = ExtManagementSystem.find(provider_id)
          expect(provider).to have_endpoint_attributes(default_connection["endpoint"])
          expect(provider.authentication_token).to eq(token(default_connection))

          expect(provider.connection_configurations.prometheus.endpoint).to have_endpoint_attributes(
            prometheus_connection["endpoint"]
          )

          expect(provider.connection_configurations.prometheus_alerts.endpoint).to have_endpoint_attributes(
            prometheus_alerts_connection["endpoint"]
          )
          expect(provider.authentication_token(:prometheus)).to eq(token(prometheus_connection))
          expect(provider.authentication_token(:prometheus_alerts)).to eq(token(prometheus_alerts_connection))
        end
      end
    end
  end

  describe "Providers edit" do
    before(:each) do
      require "ovirtsdk4" # incase it hasn't been autoloaded yet

      allow(OvirtSDK4::Probe).to receive(:probe)
        .and_return([OvirtSDK4::ProbeResult.new(:version => '3')])
    end

    it "rejects resource edits without appropriate role" do
      api_basic_authorize

      post(api_providers_url, :params => gen_request(:edit, "name" => "provider name", "href" => api_provider_url(nil, 999_999)))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects edits for invalid resources" do
      api_basic_authorize collection_action_identifier(:providers, :edit)

      post(api_provider_url(nil, 999_999), :params => gen_request(:edit, "name" => "updated provider name"))

      expect(response).to have_http_status(:not_found)
    end

    it "supports single resource edit" do
      api_basic_authorize collection_action_identifier(:providers, :edit)

      provider = FactoryBot.create(:ems_redhat_v4, sample_rhevm.except("credentials"))

      post(api_provider_url(nil, provider), :params => gen_request(:edit, "name" => "updated provider", "port" => "8080"))

      expect_single_resource_query("id" => provider.id.to_s, "name" => "updated provider")
      expect(provider.reload.name).to eq("updated provider")
      expect(provider.port).to eq(8080)
    end

    it "supports editing per provider options" do
      api_basic_authorize collection_action_identifier(:providers, :edit)

      provider = FactoryBot.create(:ems_redhat_v4, sample_rhevm.except("credentials"))

      options = {"hello" => "world"}
      options_symbolized = options.deep_symbolize_keys
      post(api_provider_url(nil, provider), :params => gen_request(:edit,
                                                                   "options" => options))
      expect(provider.reload.options).to eq(options_symbolized)
    end

    it "only returns real attributes" do
      api_basic_authorize collection_action_identifier(:providers, :edit)

      provider = FactoryBot.create(:ems_redhat_v4, sample_rhevm.except("credentials"))

      post(api_provider_url(nil, provider), :params => gen_request(:edit, "name" => "updated provider", "port" => "8080"))

      response_keys = response.parsed_body.keys
      expect(response_keys).to include("tenant_id")
      expect(response_keys).not_to include("total_vms")
    end

    it "supports updates of credentials" do
      api_basic_authorize collection_action_identifier(:providers, :edit)

      provider = FactoryBot.create(:ext_management_system, sample_vmware.except("credentials"))
      provider.update_authentication(:default => default_credentials.symbolize_keys)

      post(api_provider_url(nil, provider), :params => gen_request(:edit,
                                                                   "name"        => "updated vmware",
                                                                   "credentials" => {"userid" => "superadmin"}))

      expect_single_resource_query("id" => provider.id.to_s, "name" => "updated vmware")
      expect(provider.reload.name).to eq("updated vmware")
      expect(provider.authentication_userid).to eq("superadmin")
    end

    CONTAINERS_CLASSES.each do |name, klass|
      context name do
        let(:containers_class) { klass }

        it "does not schedule a new credentials check if endpoint does not change" do
          api_basic_authorize collection_action_identifier(:providers, :edit)

          provider = FactoryBot.create(:ext_management_system, sample_containers_multi_end_point_with_hawkular)
          MiqQueue.where(:method_name => "authentication_check_types",
                         :class_name  => "ExtManagementSystem",
                         :instance_id => provider.id).delete_all

          post(api_provider_url(nil, provider), :params => gen_request(:edit,
                                                                       "connection_configurations" => [default_connection,
                                                                                                       hawkular_connection]))

          queue_jobs = MiqQueue.where(:method_name => "authentication_check_types",
                                      :class_name  => "ExtManagementSystem",
                                      :instance_id => provider.id)
          expect(queue_jobs).to be
          expect(queue_jobs.length).to eq(0)
        end

        it "schedules a new credentials check if endpoint change" do
          api_basic_authorize collection_action_identifier(:providers, :edit)

          provider = FactoryBot.create(:ems_kubernetes)
          MiqQueue.where(:method_name => "authentication_check_types",
                         :class_name  => "ExtManagementSystem",
                         :instance_id => provider.id).delete_all

          post(api_provider_url(nil, provider), :params => gen_request(:edit,
                                                                       "connection_configurations" => [updated_connection,
                                                                                                       hawkular_connection]))

          provider.reload
          expect(provider).to have_endpoint_attributes(updated_connection["endpoint"])

          queue_jobs = MiqQueue.where(:method_name => "authentication_check_types",
                                      :class_name  => "ExtManagementSystem",
                                      :instance_id => provider.id)
          expect(queue_jobs).to be
          expect(queue_jobs.length).to eq(1)
          expect(queue_jobs[0].args[0][0]).to eq(:bearer)
        end
      end
    end

    it "supports additions of credentials" do
      api_basic_authorize collection_action_identifier(:providers, :edit)

      provider = FactoryBot.create(:ems_redhat)
      provider.update_authentication(:default => default_credentials.symbolize_keys)

      post(api_provider_url(nil, provider), :params => gen_request(:edit,
                                                                   "name"        => "updated redhat",
                                                                   "credentials" => [metrics_credentials]))

      expect_single_resource_query("id" => provider.id.to_s, "name" => "updated redhat")
      expect(provider.reload.name).to eq("updated redhat")
      expect(provider.authentication_userid).to eq(default_credentials["userid"])
      expect(provider.authentication_userid(:metrics)).to eq(metrics_credentials["userid"])
    end

    it "supports multiple resource edits" do
      api_basic_authorize collection_action_identifier(:providers, :edit)

      p1 = FactoryBot.create(:ems_redhat, :name => "name1")
      p2 = FactoryBot.create(:ems_redhat, :name => "name2")

      post(api_providers_url, :params => gen_request(:edit,
                                                     [{"href" => api_provider_url(nil, p1), "name" => "updated name1"},
                                                      {"href" => api_provider_url(nil, p2), "name" => "updated name2"}]))

      expect_results_to_match_hash("results",
                                   [{"id" => p1.id.to_s, "name" => "updated name1"},
                                    {"id" => p2.id.to_s, "name" => "updated name2"}])

      expect(p1.reload.name).to eq("updated name1")
      expect(p2.reload.name).to eq("updated name2")
    end
  end

  describe "Providers delete" do
    it "rejects deletion without appropriate role" do
      api_basic_authorize

      post(api_providers_url, :params => gen_request(:delete, "name" => "provider name", "href" => api_provider_url(nil, 100)))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects deletion without appropriate role" do
      api_basic_authorize

      delete(api_provider_url(nil, 100))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects deletes for invalid providers" do
      api_basic_authorize collection_action_identifier(:providers, :delete)

      delete(api_provider_url(nil, 999_999))

      expect(response).to have_http_status(:not_found)
    end

    it "supports single provider delete" do
      api_basic_authorize collection_action_identifier(:providers, :delete)

      provider = FactoryBot.create(:ext_management_system, :name => "provider", :hostname => "provider.com")

      delete(api_provider_url(nil, provider))

      expect(response).to have_http_status(:no_content)
    end

    it "supports single provider delete action" do
      api_basic_authorize collection_action_identifier(:providers, :delete)

      provider = FactoryBot.create(:ext_management_system, :name => "provider", :hostname => "provider.com")

      post(api_provider_url(nil, provider), :params => gen_request(:delete))

      expect_single_action_result(:success   => true,
                                  :message   => "deleting",
                                  :task_href => api_tasks_url,
                                  :task      => true,
                                  :href      => api_provider_url(nil, provider))
    end

    it "supports multiple provider deletes" do
      api_basic_authorize collection_action_identifier(:providers, :delete)

      p1 = FactoryBot.create(:ext_management_system, :name => "provider name 1")
      p2 = FactoryBot.create(:ext_management_system, :name => "provider name 2")

      post(api_providers_url, :params => gen_request(:delete,
                                                     [{"href" => api_provider_url(nil, p1)},
                                                      {"href" => api_provider_url(nil, p2)}]))
      expected = {
        "results" => [
          a_hash_including('task_href' => a_string_including(api_tasks_url)),
          a_hash_including('task_href' => a_string_including(api_tasks_url))
        ]
      }
      expect_multiple_action_result(2, :task => true)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Providers refresh" do
    def failed_auth_action(id)
      {"success" => false, "message" => /failed last authentication check/i, "href" => api_provider_url(nil, id)}
    end

    it "rejects refresh requests without appropriate role" do
      api_basic_authorize

      post(api_provider_url(nil, 100), :params => gen_request(:refresh))

      expect(response).to have_http_status(:forbidden)
    end

    it "supports single provider refresh" do
      api_basic_authorize collection_action_identifier(:providers, :refresh)

      provider = FactoryBot.create(:ext_management_system, sample_vmware.symbolize_keys.except(:type, :credentials))
      provider.update_authentication(:default => default_credentials.symbolize_keys)

      post(api_provider_url(nil, provider), :params => gen_request(:refresh))

      expect_single_action_result(failed_auth_action(provider.id.to_s).symbolize_keys)
    end

    it "supports cloud provider refresh" do
      api_basic_authorize 'ems_cloud_refresh'

      provider = FactoryBot.create(:ext_management_system, sample_amazon.symbolize_keys.except(:type, :credentials))
      provider.update_authentication(:default => default_credentials.symbolize_keys)

      post(api_provider_url(nil, provider), :params => gen_request(:refresh))

      expect_single_action_result(failed_auth_action(provider.id.to_s).symbolize_keys)
    end

    it "supports multiple provider refreshes" do
      api_basic_authorize collection_action_identifier(:providers, :refresh)

      p1 = FactoryBot.create(:ext_management_system, sample_vmware.symbolize_keys.except(:type, :credentials))
      p1.update_authentication(:default => default_credentials.symbolize_keys)

      p2 = FactoryBot.create(:ext_management_system, sample_rhevm.symbolize_keys.except(:type, :credentials))
      p2.update_authentication(:default => default_credentials.symbolize_keys)

      post(api_providers_url, :params => gen_request(:refresh, [{"href" => api_provider_url(nil, p1)},
                                                                {"href" => api_provider_url(nil, p2)}]))
      expect(response).to have_http_status(:ok)
      expect_results_to_match_hash("results", [failed_auth_action(p1.id.to_s), failed_auth_action(p2.id.to_s)])
    end

    it "provider refresh are created with a task" do
      api_basic_authorize collection_action_identifier(:providers, :refresh)

      provider = FactoryBot.create(:ext_management_system, sample_vmware.symbolize_keys.except(:type, :credentials))
      provider.update_authentication(:default => default_credentials.symbolize_keys)
      provider.authentication_type(:default).update(:status => "Valid")

      post(api_provider_url(nil, provider), :params => gen_request(:refresh))

      expect_single_action_result(:success => true,
                                  :message => a_string_matching("Provider .* refreshing"),
                                  :href    => api_provider_url(nil, provider),
                                  :task    => true)
    end

    it "provider refresh for provider_class=provider are created with a task" do
      api_basic_authorize collection_action_identifier(:providers, :refresh)

      provider = FactoryBot.create(:provider_foreman, :zone => @zone, :url => "example.com", :verify_ssl => false)
      provider.update_authentication(:default => default_credentials.symbolize_keys)
      provider.authentication_type(:default).update(:status => "Valid")

      post(api_provider_url(nil, provider) + '?provider_class=provider', :params => gen_request(:refresh))

      expect_single_action_result(:success => true,
                                  :message => a_string_matching("Provider .* refreshing"),
                                  :href    => api_provider_url(nil, provider),
                                  :task    => true)
    end

    it "provider refresh for provider_class=provider are created with multiple tasks for multi-manager providers" do
      api_basic_authorize collection_action_identifier(:providers, :refresh)

      provider = FactoryBot.create(:provider_foreman, :zone => @zone, :url => "example.com", :verify_ssl => false)
      provider.update_authentication(:default => default_credentials.symbolize_keys)
      provider.authentication_type(:default).update(:status => "Valid")

      post(api_provider_url(nil, provider) + '?provider_class=provider', :params => gen_request(:refresh))

      expected = {
        "success"   => true,
        "message"   => a_string_matching("Provider .* refreshing"),
        "href"      => api_provider_url(nil, provider),
        "task_id"   => a_kind_of(String),
        "task_href" => a_string_matching(api_tasks_url),
        "tasks"     => [a_hash_including("id" => a_kind_of(String), "href" => a_string_matching(api_tasks_url)),
                        a_hash_including("id" => a_kind_of(String), "href" => a_string_matching(api_tasks_url))]
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'Providers import VM' do
    let(:provider)      { FactoryBot.create(:ems_redhat, sample_rhevm.except("credentials")) }
    let(:provider_url)  { api_provider_url(nil, provider) }

    let(:vm)            { FactoryBot.create(:vm_vmware) }
    let(:vm_url)        { api_vm_url(nil, vm) }

    let(:cluster)       { FactoryBot.create(:ems_cluster) }
    let(:cluster_url)   { api_cluster_url(nil, cluster) }

    let(:storage)       { FactoryBot.create(:storage) }
    let(:storage_url)   { api_data_store_url(nil, storage) }

    NAME = 'new_vm_name'.freeze

    def gen_import_request
      gen_request(
        :import_vm,
        :source => { :href => vm_url },
        :target => {
          :name       => NAME,
          :cluster    => { :href => cluster_url },
          :data_store => { :href => storage_url },
          :sparse     => true
        }
      )
    end

    it 'rejects import without appropriate role' do
      api_basic_authorize

      post(provider_url, :params => gen_import_request)

      expect(response).to have_http_status(:forbidden)
    end

    it 'enqueues a correct import request' do
      api_basic_authorize action_identifier(:providers, :import_vm)

      post(provider_url, :params => gen_import_request)

      expect_single_action_result(:success => true, :task => true)
      queue_jobs = MiqQueue.where(:method_name => 'import_vm',
                                  :class_name  => 'ManageIQ::Providers::Redhat::InfraManager',
                                  :instance_id => provider.id)
      expected_args = [vm.id,
                       {
                         :name       => NAME,
                         :cluster_id => cluster.id,
                         :storage_id => storage.id,
                         :sparse     => true
                       }]
      expect(queue_jobs).to contain_exactly(an_object_having_attributes(:args => expected_args))
    end
  end

  describe 'change provider password' do
    let(:ems_physical_infra) { FactoryBot.create(:ems_physical_infra) }
    let(:invalid_change_password_payload) do
      { "action"           => "change_password",
        "current_password" => "current_password",
        "new_password"     => "new_password" }
    end

    let(:valid_change_password_payload) do
      { "action"           => "change_password",
        "current_password" => "current_password",
        "new_password"     => "new_password" }
    end

    let(:valid_change_password_payload_for_multiple_providers) do
      {
        "action"    => "change_password",
        "resources" => [
          {
            "href"             => api_provider_url(nil, ems_physical_infra),
            "current_password" => "current_password",
            "new_password"     => "new_password"
          },
          {
            "href"             => api_provider_url(nil, ems_physical_infra),
            "current_password" => "current_password",
            "new_password"     => "new_password"
          }
        ]
      }
    end

    let(:invalid_change_password_payload_for_multiple_providers) do
      {
        "action"    => "change_password",
        "resources" => [
          {
            "href"             => api_provider_url(nil, 999_999),
            "current_password" => "current_password",
            "new_password"     => "new_password"
          },
          {
            "href"             => api_provider_url(nil, ems_physical_infra),
            "current_password" => "current_password",
            "new_password"     => "new_password"
          }
        ]
      }
    end

    let(:single_resource_success_response) do
      {
        "message"   => a_string_matching(/Change password requested for Physical Provider #{ems_physical_infra.name}/i),
        "href"      => api_provider_url(nil, ems_physical_infra),
        "success"   => true,
        "task_id"   => a_kind_of(String),
        "task_href" => a_string_matching(api_tasks_url)
      }
    end

    let(:single_resource_fail_response) do
      {
        "success" => false,
        "message" => a_string_matching(/Couldn't find ExtManagementSystem with 'id'=999999/i)
      }
    end

    context 'with a non existent provider' do
      it 'returns a bad request error if no id is provided' do
        api_basic_authorize collection_action_identifier(:providers, :change_password)

        payload = {
          "action" => "change_password",
          "href"   => ""
        }

        post(api_providers_url, :params => payload)
        expect_bad_request("Must specify an id for change password of a providers resource")
      end

      it 'returns a not found error' do
        api_basic_authorize collection_action_identifier(:providers, :change_password)

        post(api_provider_url(nil, 999_999), :params => valid_change_password_payload)

        expect(response).to have_http_status(:not_found)
      end

      it 'returns a 200 code for multiple providers' do
        api_basic_authorize collection_action_identifier(:providers, :change_password)

        post(api_providers_url, :params => invalid_change_password_payload_for_multiple_providers)

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(single_resource_fail_response), a_hash_including(single_resource_success_response)
          )
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end

    context 'with a valid request' do
      before { allow_any_instance_of(ExtManagementSystem).to receive(:change_password) { true } }

      it 'proccess the request successfully' do
        api_basic_authorize collection_action_identifier(:providers, :change_password)

        post(api_provider_url(nil, ems_physical_infra), :params => valid_change_password_payload)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(single_resource_success_response)
      end

      it 'proccess the request successfully for multiple providers' do
        api_basic_authorize collection_action_identifier(:providers, :change_password)

        post(api_providers_url, :params => valid_change_password_payload_for_multiple_providers)

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(single_resource_success_response), a_hash_including(single_resource_success_response)
          )
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end

  describe 'query Providers' do
    describe 'query custom_attributes' do
      let!(:generic_provider) { FactoryBot.create(:provider) }
      it 'does not blow-up on provider without custom_attributes' do
        api_basic_authorize collection_action_identifier(:providers, :read, :get)
        get(api_providers_url, :params => { :expand => 'resources,custom_attributes', :provider_class => 'provider' })
        expect_query_result(:providers, 1, 1)
      end
    end
  end

  context 'load balancers subcollection' do
    before do
      @provider = FactoryBot.create(:ems_amazon_network)
      @load_balancer = FactoryBot.create(:load_balancer_amazon, :ext_management_system => @provider)
      load_balancer_listener = FactoryBot.create(:load_balancer_listener_amazon,
                                                  :ext_management_system => @provider)
      load_balancer_pool = FactoryBot.create(:load_balancer_pool_amazon,
                                              :ext_management_system => @provider)
      load_balancer_pool_member = FactoryBot.create(:load_balancer_pool_member_amazon,
                                                     :ext_management_system => @provider)
      @load_balancer.load_balancer_listeners << load_balancer_listener
      load_balancer_listener.load_balancer_pools << load_balancer_pool
      load_balancer_pool.load_balancer_pool_members << load_balancer_pool_member
    end

    it 'queries all load balancers' do
      api_basic_authorize subcollection_action_identifier(:providers, :load_balancers, :read, :get)
      expected = {
        'resources' => [
          {
            'href' => api_provider_load_balancer_url(nil, @provider, @load_balancer)
          }
        ]

      }
      get(api_provider_load_balancers_url(nil, @provider))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "will not show a provider's load balancers without the appropriate role" do
      api_basic_authorize

      get(api_provider_load_balancers_url(nil, @provider))

      expect(response).to have_http_status(:forbidden)
    end

    it 'queries a single load balancer' do
      api_basic_authorize subcollection_action_identifier(:providers, :load_balancers, :read, :get)

      get(api_provider_load_balancer_url(nil, @provider, @load_balancer))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => @load_balancer.id.to_s)
    end

    it "will not show a provider's load balancer without the appropriate role" do
      api_basic_authorize

      get(api_provider_load_balancer_url(nil, @provider, @load_balancer))

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'cloud subnets subcollection' do
    before do
      @provider = FactoryBot.create(:ems_openstack).network_manager
      @cloud_subnet = FactoryBot.create(:cloud_subnet, :ext_management_system => @provider)
    end

    it 'queries all cloud subnets' do
      api_basic_authorize subcollection_action_identifier(:providers, :cloud_subnets, :read, :get)

      get(api_provider_cloud_subnets_url(nil, @provider))

      expected = {
        'resources' => [
          { 'href' => api_provider_cloud_subnet_url(nil, @provider, @cloud_subnet) }
        ]

      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "will not show a provider's cloud subnets without the appropriate role" do
      api_basic_authorize

      get(api_provider_cloud_subnets_url(nil, @provider))

      expect(response).to have_http_status(:forbidden)
    end

    it 'queries a single cloud subnet' do
      api_basic_authorize action_identifier(:cloud_subnets, :read, :subresource_actions, :get)

      get(api_provider_cloud_subnet_url(nil, @provider, @cloud_subnet))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => @cloud_subnet.id.to_s)
    end

    it "will not show a provider's cloud subnet without the appropriate role" do
      api_basic_authorize

      get(api_provider_url(nil, @provider, @cloud_subnet))

      expect(response).to have_http_status(:forbidden)
    end

    it "returns an empty array for providers that return nil" do
      api_basic_authorize subcollection_action_identifier(:providers, :cloud_subnets, :read, :get)
      provider = FactoryBot.create(:ems_redhat)

      get(api_provider_cloud_subnets_url(nil, provider))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("resources" => [])
    end
  end

  context 'cloud tenants subcollection' do
    before do
      @provider = FactoryBot.create(:ems_openstack)
      @cloud_tenant = FactoryBot.create(:cloud_tenant, :ext_management_system => @provider)
    end

    it 'queries all cloud tenants' do
      api_basic_authorize subcollection_action_identifier(:providers, :cloud_tenants, :read, :get)

      get(api_provider_cloud_tenants_url(nil, @provider))

      expected = {
        'resources' => [
          { 'href' => api_provider_cloud_tenant_url(nil, @provider, @cloud_tenant) }
        ]

      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "will not show a provider's cloud tenants without the appropriate role" do
      api_basic_authorize

      get(api_provider_cloud_tenants_url(nil, @provider))

      expect(response).to have_http_status(:forbidden)
    end

    it 'queries a single cloud tenant' do
      api_basic_authorize action_identifier(:cloud_tenants, :read, :subresource_actions, :get)

      get(api_provider_cloud_tenant_url(nil, @provider, @cloud_tenant))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => @cloud_tenant.id.to_s)
    end

    it "will not show a provider's cloud tenant without the appropriate role" do
      api_basic_authorize

      get(api_provider_cloud_tenant_url(nil, @provider, @cloud_tenant))

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'security groups subcollection' do
    before do
      @provider = FactoryBot.create(:ems_openstack).network_manager
      @infra_provider = FactoryBot.create(:ems_openstack_infra)
      @security_group = FactoryBot.create(:security_group, :ext_management_system => @provider)
    end

    it 'queries all security groups from a provider that responds to security_groups' do
      api_basic_authorize subcollection_action_identifier(:providers, :security_groups, :read, :get)

      get(api_provider_security_groups_url(nil, @provider))

      expected = {
        'resources' => [
          { 'href' => api_provider_security_group_url(nil, @provider, @security_group) }
        ]

      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'does not error when querying a provider that does not respond to security_groups' do
      api_basic_authorize subcollection_action_identifier(:providers, :security_groups, :read, :get)

      get(api_provider_security_groups_url(nil, @infra_provider))

      expected = {
        'resources' => []

      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "will not show a provider's security groups without the appropriate role" do
      api_basic_authorize

      get(api_provider_security_groups_url(nil, @provider))

      expect(response).to have_http_status(:forbidden)
    end

    it 'queries a single security group' do
      api_basic_authorize action_identifier(:security_groups, :read, :subresource_actions, :get)

      get(api_provider_security_group_url(nil, @provider, @security_group))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => @security_group.id.to_s)
    end

    it "will not show a provider's security group without the appropriate role" do
      api_basic_authorize

      get(api_provider_security_group_url(nil, @provider, @security_group))

      expect(response).to have_http_status(:forbidden)
    end

    it "returns an empty array for providers that return nil" do
      api_basic_authorize subcollection_action_identifier(:providers, :security_groups, :read, :get)
      provider = FactoryBot.create(:ems_redhat)

      get(api_provider_security_groups_url(nil, provider))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("resources" => [])
    end
  end

  describe 'edit custom_attributes on providers' do
    context 'provider_class=provider' do
      let(:generic_provider) { FactoryBot.create(:provider) }
      let(:attr) { FactoryBot.create(:custom_attribute) }
      let(:url) do
        api_provider_custom_attributes_url(nil, generic_provider) + '?provider_class=provider'
      end

      it 'cannot add a custom_attribute' do
        api_basic_authorize subcollection_action_identifier(:providers, :custom_attributes, :add, :post)
        post(url, :params => gen_request(:add, :name => 'x'))
        expect_bad_request("#{generic_provider.class.name} does not support management of custom attributes")
      end

      it 'cannot edit custom_attribute' do
        api_basic_authorize subcollection_action_identifier(:providers, :custom_attributes, :edit, :post)
        post(url, :params => gen_request(:edit, :href => api_provider_custom_attribute_url(nil, generic_provider, attr)))
        expect_bad_request("#{generic_provider.class.name} does not support management of custom attributes")
      end
    end
  end

  context "OPTIONS /api/providers" do
    it "returns options for all providers when no query" do
      options(api_providers_url)
      expect(response.parsed_body["data"]["provider_settings"].keys.count).to eq(
        ManageIQ::Providers::BaseManager.leaf_subclasses.count
      )
      expect(response.parsed_body["data"]["supported_providers"].count).to eq(
        ExtManagementSystem.supported_types_for_create.count
      )
      expect(response.parsed_body["data"]["provider_settings"]["kubernetes"]["proxy_settings"]["settings"]["http_proxy"]["label"]).to eq('HTTP Proxy')
    end
  end

  context 'GET /api/providers/:id/vms' do
    it 'returns the vms for a provider with an appropriate role' do
      ems = FactoryBot.create(:ext_management_system)
      vm = FactoryBot.create(:vm_amazon, :ext_management_system => ems)
      api_basic_authorize action_identifier(:providers, :read, :resource_actions, :get)

      get(api_provider_vms_url(nil, ems))

      expected = {
        'name'      => 'vms',
        'subcount'  => 1,
        'resources' => [
          {'href' => api_provider_vm_url(nil, ems, vm)}
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'allows for expansion of vms on a provider' do
      ems = FactoryBot.create(:ext_management_system)
      vm = FactoryBot.create(:vm_amazon, :ext_management_system => ems)
      api_basic_authorize collection_action_identifier(:providers, :read, :get)
      get(api_providers_url, :params => { :expand => 'resources,vms' })

      expected = {
        'name'      => 'providers',
        'resources' => [
          a_hash_including(
            'href' => api_provider_url(nil, ems),
            'vms'  => [
              a_hash_including('href' => api_provider_vm_url(nil, ems, vm))
            ]
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'Folders subcollection' do
    let(:folder) { FactoryBot.create(:ems_folder) }
    let(:ems) { FactoryBot.create(:ext_management_system) }

    before do
      ems.add_folder(folder)
    end

    context 'GET /api/providers/:id/folders' do
      it 'returns the folders with an appropriate role' do
        api_basic_authorize(collection_action_identifier(:providers, :read, :get))

        get(api_provider_folders_url(nil, ems))

        expected = {
          'resources' => [{'href' => api_provider_folder_url(nil, ems, folder)}]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it 'does not return the folders without an appropriate role' do
        api_basic_authorize

        get(api_provider_folders_url(nil, ems))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'GET /api/providers/:id/folders/:s_id' do
      it 'returns the folder with an appropriate role' do
        api_basic_authorize action_identifier(:providers, :read, :resource_actions, :get)

        get(api_provider_folder_url(nil, ems, folder))

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('id' => folder.id.to_s)
      end

      it 'does not return the folder without an appropriate role' do
        api_basic_authorize

        get(api_provider_folder_url(nil, ems, folder))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context 'Networks subcollection' do
    let(:hardware) { FactoryBot.create(:hardware) }
    let(:network) { FactoryBot.create(:network, :hardware => hardware) }
    let(:ems) { FactoryBot.create(:ext_management_system) }

    context 'GET /api/providers/:id/networks' do
      it 'returns the networks with an appropriate role' do
        FactoryBot.create(:vm, :ext_management_system => ems, :hardware => hardware)
        api_basic_authorize(collection_action_identifier(:providers, :read, :get))

        expected = {
          'resources' => [{'href' => api_provider_network_url(nil, ems, network)}]
        }
        get(api_provider_networks_url(nil, ems))

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it 'does not return the networks without an appropriate role' do
        api_basic_authorize

        get(api_provider_networks_url(nil, ems))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'GET /api/providers/:id/networks/:s_id' do
      it 'returns the network with an appropriate role' do
        FactoryBot.create(:vm, :ext_management_system => ems, :hardware => hardware)
        api_basic_authorize action_identifier(:providers, :read, :resource_actions, :get)

        get(api_provider_network_url(nil, ems, network))

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('id' => network.id.to_s)
      end

      it 'does not return the networks without an appropriate role' do
        api_basic_authorize

        get(api_provider_network_url(nil, ems, network))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context 'Lans subcollection' do
    let(:lan) { FactoryBot.create(:lan) }
    let(:switch) { FactoryBot.create(:switch, :lans => [lan]) }
    let(:host) { FactoryBot.create(:host, :switches => [switch]) }
    let(:ems) { FactoryBot.create(:ext_management_system) }

    before do
      ems.hosts << host
    end

    context 'GET /api/providers/:id/lans' do
      it 'returns the lans with an appropriate role' do
        api_basic_authorize(collection_action_identifier(:providers, :read, :get))

        expected = {
          'resources' => [{'href' => api_provider_lan_url(nil, ems, lan)}]
        }
        get(api_provider_lans_url(nil, ems))

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it 'does not return the lans without an appropriate role' do
        api_basic_authorize

        get(api_provider_lans_url(nil, ems))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'GET /api/providers/:id/lans/:s_id' do
      it 'returns the lan with an appropriate role' do
        api_basic_authorize action_identifier(:providers, :read, :resource_actions, :get)

        get(api_provider_lan_url(nil, ems, lan))

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('id' => lan.id.to_s)
      end

      it 'does not return the lans without an appropriate role' do
        api_basic_authorize

        get(api_provider_lan_url(nil, ems, lan))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "Cloud networks subcollection" do
    it "returns an empty array for providers that return nil" do
      api_basic_authorize subcollection_action_identifier(:providers, :cloud_networks, :read, :get)
      provider = FactoryBot.create(:ems_redhat)

      get(api_provider_cloud_networks_url(nil, provider))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("resources" => [])
    end
  end
end
