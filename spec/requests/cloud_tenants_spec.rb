RSpec.describe 'CloudTenants API' do
  describe 'GET /api/cloud_tenants' do
    it 'lists all cloud tenants with an appropriate role' do
      cloud_tenant = FactoryBot.create(:cloud_tenant)
      api_basic_authorize collection_action_identifier(:cloud_tenants, :read, :get)
      get(api_cloud_tenants_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'cloud_tenants',
        'resources' => [
          hash_including('href' => api_cloud_tenant_url(nil, cloud_tenant))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids access to cloud tenants without an appropriate role' do
      api_basic_authorize

      get(api_cloud_tenants_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/cloud_tenants/:id' do
    it 'will show a cloud tenant with an appropriate role' do
      cloud_tenant = FactoryBot.create(:cloud_tenant)
      api_basic_authorize action_identifier(:cloud_tenants, :read, :resource_actions, :get)

      get(api_cloud_tenant_url(nil, cloud_tenant))

      expect(response.parsed_body).to include('href' => api_cloud_tenant_url(nil, cloud_tenant))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to a cloud tenant without an appropriate role' do
      cloud_tenant = FactoryBot.create(:cloud_tenant)
      api_basic_authorize

      get(api_cloud_tenant_url(nil, cloud_tenant))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/cloud_tenants' do
    it 'creates a cloud tenant' do
      ems = FactoryBot.create(:ems_openstack)
      api_basic_authorize collection_action_identifier(:cloud_tenants, :create, :post)

      post(api_cloud_tenants_url, :params => {:name => 'foo', :ems_id => ems.id})

      expected = {
        'results' => [a_hash_including(
          'success' => true,
          'message' => a_string_including('Creating Cloud Tenant'),
          'task_id' => a_kind_of(String)
        )]
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  [:patch, :put].each do |request|
    describe "#{request.to_s.upcase} /api/cloud_tenants/:id" do
      it 'updates a cloud tenant' do
        cloud_tenant = FactoryBot.create(:cloud_tenant, :ext_management_system => FactoryBot.create(:ems_openstack))
        api_basic_authorize action_identifier(:cloud_tenants, :edit)

        send(request, api_cloud_tenant_url(nil, cloud_tenant), :params => [:name => 'foo'])

        expected = {
          'success' => true,
          'message' => a_string_including('Updating Cloud Tenant'),
          'task_id' => a_kind_of(String)
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end

  describe 'DELETE /api/cloud_tenants/:id' do
    it 'deletes a cloud tenant' do
      cloud_tenant = FactoryBot.create(:cloud_tenant, :ext_management_system => FactoryBot.create(:ems_openstack))

      api_basic_authorize action_identifier(:cloud_tenants, :delete, :resource_actions, :delete)

      delete(api_cloud_tenant_url(nil, cloud_tenant))

      expect(response).to have_http_status(:no_content)
    end
  end

  context 'security groups subcollection' do
    before do
      @cloud_tenant = FactoryBot.create(:cloud_tenant)
      @security_group = FactoryBot.create(:security_group, :cloud_tenant => @cloud_tenant)
    end

    it 'queries all security groups from a cloud tenant' do
      api_basic_authorize subcollection_action_identifier(:cloud_tenants, :security_groups, :read, :get)

      get(api_cloud_tenant_security_groups_url(nil, @cloud_tenant))

      expected = {
        'resources' => [
          { 'href' => api_cloud_tenant_security_group_url(nil, @cloud_tenant, @security_group) }
        ]

      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "will not show a cloud tenant's security groups without the appropriate role" do
      api_basic_authorize

      get(api_cloud_tenant_security_groups_url(nil, @cloud_tenant))

      expect(response).to have_http_status(:forbidden)
    end

    it 'queries a single security group' do
      api_basic_authorize action_identifier(:security_groups, :read, :subresource_actions, :get)

      get(api_cloud_tenant_security_group_url(nil, @cloud_tenant, @security_group))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => @security_group.id.to_s)
    end

    it "will not show a cloud tenant's security group without the appropriate role" do
      api_basic_authorize

      get(api_cloud_tenant_security_group_url(nil, @cloud_tenant, @security_group))

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'As a subcollection' do
    it 'returns an empty array for collections that do not have cloud tenants' do
      ems_infra = FactoryBot.create(:ems_infra)
      api_basic_authorize(subcollection_action_identifier(:providers, :cloud_tenants, :read, :get))

      get(api_provider_cloud_tenants_url(nil, ems_infra))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('resources' => [])
    end
  end
end
