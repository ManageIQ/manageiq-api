RSpec.describe 'CloudSubnets API' do
  let(:ems) { FactoryGirl.create(:ems_network) }

  describe 'GET /api/cloud_subnets' do
    it 'lists all cloud subnets with an appropriate role' do
      cloud_subnet = FactoryGirl.create(:cloud_subnet)
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
      cloud_subnet = FactoryGirl.create(:cloud_subnet)
      api_basic_authorize action_identifier(:cloud_subnets, :read, :resource_actions, :get)

      get(api_cloud_subnet_url(nil, cloud_subnet))

      expect(response.parsed_body).to include('href' => api_cloud_subnet_url(nil, cloud_subnet))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to a cloud tenant without an appropriate role' do
      cloud_subnet = FactoryGirl.create(:cloud_subnet)
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
end
