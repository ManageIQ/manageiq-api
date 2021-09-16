RSpec.describe 'CloudSubnets API' do
  let(:ems) { FactoryBot.create(:ems_network) }

  describe 'GET /api/cloud_subnets' do
    it 'lists all cloud subnets with an appropriate role' do
      cloud_subnet = FactoryBot.create(:cloud_subnet)
      api_basic_authorize collection_action_identifier(:cloud_subnets, :read, :get)
      get(api_cloud_subnets_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'cloud_subnets',
        'resources' => [
          hash_including('href' => api_cloud_subnet_url(nil, cloud_subnet))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids access to cloud subnets without an appropriate role' do
      api_basic_authorize

      get(api_cloud_subnets_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/cloud_subnets/:id' do
    it 'will show a cloud subnet with an appropriate role' do
      cloud_subnet = FactoryBot.create(:cloud_subnet)
      api_basic_authorize action_identifier(:cloud_subnets, :read, :resource_actions, :get)

      get(api_cloud_subnet_url(nil, cloud_subnet))

      expect(response.parsed_body).to include('href' => api_cloud_subnet_url(nil, cloud_subnet))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to a cloud tenant without an appropriate role' do
      cloud_subnet = FactoryBot.create(:cloud_subnet)
      api_basic_authorize

      get(api_cloud_subnet_url(nil, cloud_subnet))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/providers/:c_id/cloud_subnets" do
    it "can queue the creation of a subnet" do
      api_basic_authorize(action_identifier(:cloud_subnets, :create, :subcollection_actions))

      post(api_provider_cloud_subnets_url(nil, ems), :params => { :name => "test-subnet" })

      expected = {
        'results' => [
          a_hash_including(
            "success"   => true,
            "message"   => "Creating subnet test-subnet",
            "task_id"   => anything,
            "task_href" => a_string_matching(api_tasks_url)
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "will not create a subnet unless authorized" do
      api_basic_authorize

      post(api_provider_cloud_subnets_url(nil, ems), :params => { :name => "test-flavor" })

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'OPTIONS /api/cloud_subnets?ems_id=:id' do
    it 'returns a DDF schema when available via OPTIONS' do
      zone = FactoryBot.create(:zone, :name => "api_zone")
      provider = FactoryBot.create(:ems_network, :zone => zone)

      allow(provider.class::CloudSubnet).to receive(:params_for_create).and_return('foo')

      options(api_cloud_subnets_url, :params => {:ems_id => provider.id})
      options("#{api_cloud_subnets_url}?ems_id=#{provider.id}")

      expect(response.parsed_body['data']['form_schema']).to eq('foo')
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /api/cloud_subnets' do
    it 'forbids access to cloud subnets without an appropriate role' do
      api_basic_authorize
      post(api_cloud_subnets_url, :params => gen_request(:query, ""))
      expect(response).to have_http_status(:forbidden)
    end

    it "queues the creating of cloud subnet" do
      api_basic_authorize collection_action_identifier(:cloud_subnets, :create)
      request = {
        "action"   => "create",
        "resource" => {
          "ems_id" => ems.id,
          "name"   => "test_cloud_subnet"
        }
      }

      post(api_cloud_subnets_url, :params => request)

      expect_multiple_action_result(1, :success => true, :message => "Creating Cloud Subnet test_cloud_subnet for Provider: #{ems.name}", :task => true)
    end

    it "raises error when provider does not support creating of cloud subnets" do
      api_basic_authorize collection_action_identifier(:cloud_subnets, :create)
      provider = FactoryBot.create(:ems_amazon, :name => 'test_provider')
      request = {
        "action"   => "create",
        "resource" => {
          "ems_id" => provider.network_manager.id,
          "name"   => "test_cloud_subnet"
        }
      }

      post(api_cloud_subnets_url, :params => request)

      expected = {"success" => false, "message" => a_string_including("Cannot create cloud subnet for Provider #{provider.name}")}
      expect(response.parsed_body["results"].first).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /api/cloud_subnets/:id" do
    let(:tenant) { FactoryBot.create(:cloud_tenant_openstack, :ext_management_system => ems) }
    let(:cloud_subnet) { FactoryBot.create(:cloud_subnet_openstack, :ext_management_system => ems, :cloud_tenant => tenant) }

    it "can queue the updating of a cloud subnet" do
      api_basic_authorize(action_identifier(:cloud_subnets, :edit))

      post(api_cloud_subnet_url(nil, cloud_subnet), :params => {:action => 'edit', :status => "inactive"})

      expected = {
        'success'   => true,
        'message'   => a_string_including('Updating Cloud Subnet'),
        'task_href' => a_string_matching(api_tasks_url),
        'task_id'   => a_kind_of(String)
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can't queue the updating of a cloud subnet unless authorized" do
      api_basic_authorize

      post(api_cloud_subnet_url(nil, cloud_subnet), :params => {:action => 'edit', :status => "inactive"})
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/cloud_subnets" do
    let(:cloud_subnet) { FactoryBot.create(:cloud_subnet_openstack) }

    it "can delete a cloud subnet" do
      api_basic_authorize(action_identifier(:cloud_subnets, :delete))

      delete(api_cloud_subnet_url(nil, cloud_subnet))

      expect(response).to have_http_status(:no_content)
    end

    it "will not delete a cloud subnet unless authorized" do
      api_basic_authorize

      delete(api_cloud_subnet_url(nil, cloud_subnet))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/cloud_subnets with delete action" do
    it "can delete a cloud subnet" do
      ems = FactoryBot.create(:ems_network)
      cloud_subnet = FactoryBot.create(:cloud_subnet_openstack, :ext_management_system => ems)
      api_basic_authorize(action_identifier(:cloud_subnets, :delete, :resource_actions))

      post(api_cloud_subnet_url(nil, cloud_subnet), :params => gen_request(:delete))

      expected = {
        'success'   => true,
        'message'   => a_string_including('Deleting Cloud Subnet'),
        'task_href' => a_string_matching(api_tasks_url),
        'task_id'   => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "will not delete a cloud subnet unless authorized" do
      cloud_subnet = FactoryBot.create(:cloud_subnet)
      api_basic_authorize

      post(api_cloud_subnet_url(nil, cloud_subnet), :params => {:action => "delete"})

      expect(response).to have_http_status(:forbidden)
    end

    it "can delete multiple cloud_subnets" do
      ems = FactoryBot.create(:ems_network)
      cloud_subnet1, cloud_subnet2 = FactoryBot.create_list(:cloud_subnet_openstack, 2, :ext_management_system => ems)
      api_basic_authorize(action_identifier(:cloud_subnets, :delete, :resource_actions))

      post(api_cloud_subnets_url, :params => {:action => "delete", :resources => [{:id => cloud_subnet1.id}, {:id => cloud_subnet2.id}]})

      expect(response).to have_http_status(:ok)
    end

    it "forbids multiple cloud subnet deletion without an appropriate role" do
      cloud_subnet1, cloud_subnet2 = FactoryBot.create_list(:cloud_subnet, 2)
      api_basic_authorize

      post(api_cloud_subnets_url, :params => {:action => "delete", :resources => [{:id => cloud_subnet1.id}, {:id => cloud_subnet2.id}]})

      expect(response).to have_http_status(:forbidden)
    end

    it "raises an error when delete not supported for cloud subnet" do
      cloud_subnet = FactoryBot.create(:cloud_subnet)
      api_basic_authorize(action_identifier(:cloud_subnets, :delete, :resource_actions))

      post(api_cloud_subnet_url(nil, cloud_subnet), :params => gen_request(:delete))

      expected = {
        'success' => false,
        'message' => a_string_including('Cannot delete Cloud Subnet')
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end
  end
end
