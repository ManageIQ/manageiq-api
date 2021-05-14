describe "tenant quotas API" do
  let(:tenant) { FactoryBot.create(:tenant) }

  context "with an appropriate role" do
    it "can list all the quotas form a tenant" do
      api_basic_authorize subcollection_action_identifier(:tenants, :quotas, :read, :get)

      quota_1 = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)
      quota_2 = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :mem_allocated, :value => 20)

      get "/api/tenants/#{tenant.id}/quotas"

      expect_result_resources_to_include_hrefs(
        "resources",
        [
          api_tenant_quota_url(nil, tenant, quota_1),
          api_tenant_quota_url(nil, tenant, quota_2)
        ]
      )

      expect(response).to have_http_status(:ok)
    end

    it "can show a single quota from a tenant" do
      api_basic_authorize subcollection_action_identifier(:tenants, :quotas, :read, :get)

      quota = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)

      get "/api/tenants/#{tenant.id}/quotas/#{quota.id}"

      expect_result_to_match_hash(
        response.parsed_body,
        "href"      => api_tenant_quota_url(nil, tenant, quota),
        "id"        => quota.id.to_s,
        "tenant_id" => tenant.id.to_s,
        "name"      => "cpu_allocated",
        "unit"      => "fixnum",
        "value"     => 1.0
      )
      expect(response).to have_http_status(:ok)
    end

    context 'with dynamic tenant features' do
      let!(:tenant_alpha) { FactoryBot.create(:tenant, :name => "alpha", :parent => Tenant.root_tenant) }
      let!(:tenant_omega) { FactoryBot.create(:tenant, :name => "omega", :parent => tenant_alpha) }

      before do
        EvmSpecHelper.seed_specific_product_features("rbac_tenant_manage_quotas")
        @group.update(:tenant => tenant_alpha)
      end

      it "cannot create a quota for alpha tenant without tenant product permission for alpha tenant" do
        api_basic_authorize "rbac_tenant_manage_quotas_tenant_#{tenant_omega.id}"

        expect do
          post "/api/tenants/#{tenant_alpha.id}/quotas/", :params => { :name => :cpu_allocated, :value => 1 }
        end.not_to change(TenantQuota, :count)

        expect(response).to have_http_status(:forbidden)
      end

      it "can create a quota from a tenant omega with tenant product permission for omega" do
        api_basic_authorize "rbac_tenant_manage_quotas_tenant_#{tenant_omega.id}"

        expected = {
          'results' => [
            a_hash_including('href' => a_string_including(api_tenant_quotas_url(nil, tenant_omega)))
          ]
        }

        expect do
          post "/api/tenants/#{tenant_omega.id}/quotas/", :params => { :name => :cpu_allocated, :value => 1 }
        end.to change(TenantQuota, :count).by(1)
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end

    it "can create a quota from a tenant" do
      api_basic_authorize action_identifier(:quotas, :create, :subcollection_actions, :post)

      expected = {
        'results' => [
          a_hash_including('href' => a_string_including(api_tenant_quotas_url(nil, tenant)))
        ]
      }
      expect do
        post "/api/tenants/#{tenant.id}/quotas/", :params => { :name => :cpu_allocated, :value => 1 }
      end.to change(TenantQuota, :count).by(1)
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can update a quota from a tenant with POST" do
      api_basic_authorize action_identifier(:quotas, :edit, :subresource_actions, :post)

      quota = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)

      options = {:value => 5}

      post "/api/tenants/#{tenant.id}/quotas/#{quota.id}", :params => gen_request(:edit, options)

      expect(response).to have_http_status(:ok)
      quota.reload
      expect(quota.value).to eq(5)
    end

    it "can update a quota from a tenant with PUT" do
      api_basic_authorize action_identifier(:quotas, :edit, :subresource_actions, :put)

      quota = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)

      options = {:value => 5}

      put "/api/tenants/#{tenant.id}/quotas/#{quota.id}", :params => options

      expect(response).to have_http_status(:ok)
      quota.reload
      expect(quota.value).to eq(5)
      expect(response.parsed_body).to include('href' => api_tenant_quota_url(nil, tenant, quota))
    end

    it "can update multiple quotas from a tenant with POST" do
      api_basic_authorize action_identifier(:quotas, :edit, :subcollection_actions, :post)

      quota_1 = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)
      quota_2 = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :mem_allocated, :value => 2)

      options = [
        {"href" => "/api/tenants/#{tenant.id}/quotas/#{quota_1.id}", "value" => 3},
        {"href" => "/api/tenants/#{tenant.id}/quotas/#{quota_2.id}", "value" => 4},
      ]

      post "/api/tenants/#{tenant.id}/quotas/", :params => gen_request(:edit, options)

      expect(response).to have_http_status(:ok)
      expect_results_to_match_hash(
        "results",
        [{"id" => quota_1.id.to_s, "value" => 3},
         {"id" => quota_2.id.to_s, "value" => 4}]
      )
      expect(quota_1.reload.value).to eq(3)
      expect(quota_2.reload.value).to eq(4)
    end

    it "can delete a quota from a tenant with POST" do
      api_basic_authorize action_identifier(:quotas, :delete, :subresource_actions, :post)

      quota = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)

      expect do
        post "/api/tenants/#{tenant.id}/quotas/#{quota.id}", :params => gen_request(:delete)
      end.to change(TenantQuota, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it "can delete a quota from a tenant with DELETE" do
      api_basic_authorize action_identifier(:quotas, :delete, :subresource_actions, :delete)

      quota = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)

      expect do
        delete "/api/tenants/#{tenant.id}/quotas/#{quota.id}"
      end.to change(TenantQuota, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "supports OPTIONS requests on a subcollection without authorization" do
      options api_tenant_quotas_url(nil, tenant)
      expect(response).to have_http_status(:ok)
    end

    it "can delete multiple quotas from a tenant with POST" do
      api_basic_authorize action_identifier(:quotas, :delete, :subcollection_actions, :post)

      quota_1 = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)
      quota_2 = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :mem_allocated, :value => 2)

      options = [
        {"href" => "/api/tenants/#{tenant.id}/quotas/#{quota_1.id}"},
        {"href" => "/api/tenants/#{tenant.id}/quotas/#{quota_2.id}"}
      ]

      expect do
        post "/api/tenants/#{tenant.id}/quotas/", :params => gen_request(:delete, options)
      end.to change(TenantQuota, :count).by(-2)

      expect(response).to have_http_status(:ok)
    end
  end

  context "without an appropriate role" do
    it "will not create a tenant quota" do
      api_basic_authorize

      expect do
        post "/api/tenants/#{tenant.id}/quotas/", :params => { :name => :cpu_allocated, :value => 1 }
      end.not_to change(TenantQuota, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "will not update a tenant quota with POST" do
      api_basic_authorize

      quota = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)

      options = {:value => 5}

      post "/api/tenants/#{tenant.id}/quotas/#{quota.id}", :params => gen_request(:edit, options)

      expect(response).to have_http_status(:forbidden)
      quota.reload
      expect(quota.value).to eq(1)
    end

    it "will not update a tenant quota with PUT" do
      api_basic_authorize

      quota = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)

      options = {:value => 5}

      put "/api/tenants/#{tenant.id}/quotas/#{quota.id}", :params => options

      expect(response).to have_http_status(:forbidden)
      quota.reload
      expect(quota.value).to eq(1)
    end

    it "will not update multiple tenant quotas with POST" do
      api_basic_authorize

      quota_1 = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)
      quota_2 = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :mem_allocated, :value => 2)

      options = [
        {"href" => "/api/tenants/#{tenant.id}/quotas/#{quota_1.id}"},
        {"href" => "/api/tenants/#{tenant.id}/quotas/#{quota_2.id}"}
      ]

      post "/api/tenants/#{tenant.id}/quotas/", :params => gen_request(:edit, options)

      expect(response).to have_http_status(:forbidden)
      expect(quota_1.reload.value).to eq(1)
      expect(quota_2.reload.value).to eq(2)
    end

    it "will not delete a tenant quota with POST" do
      api_basic_authorize

      quota = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)

      expect do
        post "/api/tenants/#{tenant.id}/quotas/#{quota.id}", :params => gen_request(:delete)
      end.not_to change(TenantQuota, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "will not delete a tenant quota with DELETE" do
      api_basic_authorize

      quota = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)

      expect do
        delete "/api/tenants/#{tenant.id}/quotas/#{quota.id}"
      end.not_to change(TenantQuota, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "will not update multiple tenants with POST" do
      api_basic_authorize

      quota_1 = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :cpu_allocated, :value => 1)
      quota_2 = FactoryBot.create(:tenant_quota, :tenant_id => tenant.id, :name => :mem_allocated, :value => 2)

      options = [
        {"href" => "/api/tenants/#{tenant.id}/quotas/#{quota_1.id}"},
        {"href" => "/api/tenants/#{tenant.id}/quotas/#{quota_2.id}"}
      ]

      expect do
        post "/api/tenants/#{tenant.id}/quotas/", :params => gen_request(:delete, options)
      end.not_to change(TenantQuota, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
