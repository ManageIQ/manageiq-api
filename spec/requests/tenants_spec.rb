RSpec.describe "tenants API" do
  let!(:root_tenant) { Tenant.seed }

  describe "custom_api_user_role_allows_method?" do
    it "validates role in basic way for requests about some action of tenants" do
      expect(Api::TenantsController.new.custom_api_user_role_allows_method?('rbac_tenant_add')).to be_falsey
    end

    it "validates role in custom way for requests about managing tenant quotas" do
      expect(Api::TenantsController.new.custom_api_user_role_allows_method?('rbac_tenant_manage_quotas')).to be_truthy
    end
  end

  it "can list all the tenants" do
    api_basic_authorize action_identifier(:tenants, :read, :collection_actions, :get)
    tenant_1 = FactoryBot.create(:tenant, :parent => root_tenant)
    tenant_2 = FactoryBot.create(:tenant, :parent => root_tenant)

    get api_tenants_url

    expect_result_resources_to_include_hrefs(
      "resources",
      [
        api_tenant_url(nil, root_tenant),
        api_tenant_url(nil, tenant_1),
        api_tenant_url(nil, tenant_2)
      ]
    )

    expect(response).to have_http_status(:ok)
  end

  it "can show a single tenant" do
    api_basic_authorize action_identifier(:tenants, :read, :resource_actions, :get)
    tenant = FactoryBot.create(
      :tenant,
      :parent      => root_tenant,
      :name        => "Test Tenant",
      :description => "Tenant for this test"
    )

    get api_tenant_url(nil, tenant)

    expect_result_to_match_hash(
      response.parsed_body,
      "href"        => api_tenant_url(nil, tenant),
      "id"          => tenant.id.to_s,
      "name"        => "Test Tenant",
      "description" => "Tenant for this test"
    )
    expect(response).to have_http_status(:ok)
  end

  context "with an appropriate role" do
    it "can create a tenant" do
      api_basic_authorize collection_action_identifier(:tenants, :create)

      expect do
        post api_tenants_url, :params => { :parent => {:id => root_tenant.id} }
      end.to change(Tenant, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "will not create a tenant with an invalid parent" do
      api_basic_authorize collection_action_identifier(:tenants, :create)
      invalid_tenant = FactoryBot.create(:tenant, :parent => root_tenant).destroy

      expect do
        post api_tenants_url, :params => { :parent => {:id => invalid_tenant.id} }
      end.not_to change(Tenant, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "can update a tenant with POST" do
      api_basic_authorize action_identifier(:tenants, :edit)
      tenant = FactoryBot.create(
        :tenant,
        :parent      => root_tenant,
        :name        => "Test Tenant",
        :description => "Tenant for this test"
      )
      options = {:name => "New Tenant name", :description => "New Tenant description"}

      post api_tenant_url(nil, tenant), :params => gen_request(:edit, options)

      expect(response).to have_http_status(:ok)
      tenant.reload
      expect(tenant.name).to eq("New Tenant name")
      expect(tenant.description).to eq("New Tenant description")
    end

    it "can update a tenant with PUT" do
      api_basic_authorize action_identifier(:tenants, :edit)
      tenant = FactoryBot.create(
        :tenant,
        :parent      => root_tenant,
        :name        => "Test Tenant",
        :description => "Tenant for this test"
      )
      options = {:name => "New Tenant name", :description => "New Tenant description"}

      put api_tenant_url(nil, tenant), :params => options

      expect(response).to have_http_status(:ok)
      tenant.reload
      expect(tenant.name).to eq("New Tenant name")
      expect(tenant.description).to eq("New Tenant description")
    end

    context "query root tenant" do
      before do
        root_tenant.update(:name => 'Some other name')
      end

      # we used to use settings to override this (specifically the root case).
      it "shows properties from the tenant" do
        api_basic_authorize action_identifier(:tenants, :read, :resource_actions, :get)
        get api_tenant_url(nil, root_tenant)

        expect_result_to_match_hash(response.parsed_body,
                                    "href" => api_tenant_url(nil, root_tenant),
                                    "id"   => root_tenant.id.to_s,
                                    "name" => "Some other name"
                                   )
        expect(response).to have_http_status(:ok)
      end
    end

    it "can update multiple tenants with POST" do
      api_basic_authorize action_identifier(:tenants, :edit)
      tenant_1 = FactoryBot.create(
        :tenant,
        :parent => root_tenant,
        :name   => "Test Tenant 1"
      )
      tenant_2 = FactoryBot.create(
        :tenant,
        :parent => root_tenant,
        :name   => "Test Tenant 2"
      )
      options = [
        {"href" => api_tenant_url(nil, tenant_1), "name" => "Updated Test Tenant 1"},
        {"href" => api_tenant_url(nil, tenant_2), "name" => "Updated Test Tenant 2"}
      ]

      post api_tenants_url, :params => gen_request(:edit, options)

      expect(response).to have_http_status(:ok)
      expect_results_to_match_hash(
        "results",
        [{"id" => tenant_1.id.to_s, "name" => "Updated Test Tenant 1"},
         {"id" => tenant_2.id.to_s, "name" => "Updated Test Tenant 2"}]
      )
      expect(tenant_1.reload.name).to eq("Updated Test Tenant 1")
      expect(tenant_2.reload.name).to eq("Updated Test Tenant 2")
    end

    it "can delete a tenant with POST" do
      api_basic_authorize action_identifier(:tenants, :delete)
      tenant = FactoryBot.create(:tenant, :parent => root_tenant)

      expect { post api_tenant_url(nil, tenant), :params => gen_request(:delete) }.to change(Tenant, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end

    it "can delete a tenant with DELETE" do
      api_basic_authorize action_identifier(:tenants, :delete)
      tenant = FactoryBot.create(:tenant, :parent => root_tenant)

      expect { delete api_tenant_url(nil, tenant) }.to change(Tenant, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "can delete multiple tenants with POST" do
      api_basic_authorize action_identifier(:tenants, :delete)
      tenant_1 = FactoryBot.create(:tenant, :parent => root_tenant)
      tenant_2 = FactoryBot.create(:tenant, :parent => root_tenant)
      options = [
        {"href" => api_tenant_url(nil, tenant_1)},
        {"href" => api_tenant_url(nil, tenant_2)}
      ]

      expect do
        post api_tenants_url, :params => gen_request(:delete, options)
      end.to change(Tenant, :count).by(-2)
      expect(response).to have_http_status(:ok)
    end
  end

  context "without an appropriate role" do
    it "will not create a tenant" do
      api_basic_authorize

      expect do
        post api_tenants_url, :params => { :parent => {:id => root_tenant.id} }
      end.not_to change(Tenant, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "will not update a tenant with POST" do
      api_basic_authorize
      tenant = FactoryBot.create(
        :tenant,
        :parent      => root_tenant,
        :name        => "Test Tenant",
        :description => "Tenant for this test"
      )
      options = {:name => "New Tenant name", :description => "New Tenant description"}

      post api_tenant_url(nil, tenant), :params => gen_request(:edit, options)

      expect(response).to have_http_status(:forbidden)
      tenant.reload
      expect(tenant.name).to eq("Test Tenant")
      expect(tenant.description).to eq("Tenant for this test")
    end

    it "will not update a tenant with PUT" do
      api_basic_authorize
      tenant = FactoryBot.create(
        :tenant,
        :parent      => root_tenant,
        :name        => "Test Tenant",
        :description => "Tenant for this test"
      )
      options = {:name => "New Tenant name", :description => "New Tenant description"}

      put api_tenant_url(nil, tenant), :params => options

      expect(response).to have_http_status(:forbidden)
      tenant.reload
      expect(tenant.name).to eq("Test Tenant")
      expect(tenant.description).to eq("Tenant for this test")
    end

    it "will not update multiple tenants with POST" do
      api_basic_authorize
      tenant_1 = FactoryBot.create(
        :tenant,
        :parent => root_tenant,
        :name   => "Test Tenant 1"
      )
      tenant_2 = FactoryBot.create(
        :tenant,
        :parent => root_tenant,
        :name   => "Test Tenant 2"
      )
      options = [
        {"href" => api_tenant_url(nil, tenant_1), "name" => "Updated Test Tenant 1"},
        {"href" => api_tenant_url(nil, tenant_2), "name" => "Updated Test Tenant 2"}
      ]

      post api_tenants_url, :params => gen_request(:edit, options)

      expect(response).to have_http_status(:forbidden)
      expect(tenant_1.reload.name).to eq("Test Tenant 1")
      expect(tenant_2.reload.name).to eq("Test Tenant 2")
    end

    it "will not delete a tenant with POST" do
      api_basic_authorize
      tenant = FactoryBot.create(:tenant, :parent => root_tenant)

      expect { post api_tenant_url(nil, tenant), :params => gen_request(:delete) }.not_to change(Tenant, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it "will not delete a tenant with DELETE" do
      api_basic_authorize
      tenant = FactoryBot.create(:tenant, :parent => root_tenant)

      expect { delete api_tenant_url(nil, tenant) }.not_to change(Tenant, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it "will not update multiple tenants with POST" do
      api_basic_authorize
      tenant_1 = FactoryBot.create(:tenant, :parent => root_tenant)
      tenant_2 = FactoryBot.create(:tenant, :parent => root_tenant)
      options = [
        {"href" => api_tenant_url(nil, tenant_1)},
        {"href" => api_tenant_url(nil, tenant_2)}
      ]

      expect do
        post api_tenants_url, :params => gen_request(:delete, options)
      end.not_to change(Tenant, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /tenants/:id/custom_button_events' do
    let(:tenant) { FactoryBot.create(:tenant, :parent => root_tenant) }
    let(:super_admin) { FactoryBot.create(:user, :role => 'super_administrator', :userid => 'alice', :password => 'alicepassword') }
    let!(:custom_button_event) { FactoryBot.create(:custom_button_event, :target => tenant) }

    it 'returns with the custom button events for the given user' do
      api_basic_authorize(:user => super_admin.userid, :password => super_admin.password)

      get(api_tenant_custom_button_events_url(nil, tenant))

      expected = {
        "name"      => "custom_button_events",
        "count"     => 1,
        "resources" => contain_exactly(
          a_hash_including(
            'href' => a_string_matching("custom_button_events/#{custom_button_event.id}")
          )
        )
      }

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'OPTIONS /tenants' do
    it 'includes tenant quota definitions' do
      api_basic_authorize action_identifier(:tenants, :read, :collection_actions, :get)

      options(api_tenants_url)

      expect(response.parsed_body['data']).to have_key("quota_definitions")
      expect(response).to have_http_status(:ok)
    end
  end
end
