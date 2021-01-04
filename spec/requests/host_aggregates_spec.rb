RSpec.describe 'HostAggregates API' do
  describe 'GET /api/host_aggregates' do
    it 'lists all cloud tenants with an appropriate role' do
      host_aggregate = FactoryBot.create(:host_aggregate)
      api_basic_authorize collection_action_identifier(:host_aggregates, :read, :get)
      get(api_host_aggregates_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'host_aggregates',
        'resources' => [
          hash_including('href' => api_host_aggregate_url(nil, host_aggregate))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids access to cloud tenants without an appropriate role' do
      api_basic_authorize

      get(api_host_aggregates_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/host_aggregates/:id' do
    it 'will show a host aggregate with an appropriate role' do
      host_aggregate = FactoryBot.create(:host_aggregate)
      api_basic_authorize action_identifier(:host_aggregates, :read, :resource_actions, :get)

      get(api_host_aggregate_url(nil, host_aggregate))

      expect(response.parsed_body).to include('href' => api_host_aggregate_url(nil, host_aggregate))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to a host aggregate without an appropriate role' do
      host_aggregate = FactoryBot.create(:host_aggregate)
      api_basic_authorize

      get(api_host_aggregate_url(nil, host_aggregate))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/host_aggregates' do
    it 'creates a host aggregate' do
      ems = FactoryBot.create(:ems_openstack)
      api_basic_authorize collection_action_identifier(:host_aggregates, :create, :post)

      post(api_host_aggregates_url, :params => {:name => 'foo', :ems_id => ems.id})

      expected = {
        'results' => [a_hash_including(
          'success' => true,
          'message' => a_string_including('Creating Host Aggregate'),
          'task_id' => a_kind_of(String)
        )]
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  [:patch, :put].each do |request|
    describe "#{request.to_s.upcase} /api/host_aggregates/:id" do
      it 'updates a cloud tenant' do
        host_aggregate = FactoryBot.create(:host_aggregate_openstack, :ext_management_system => FactoryBot.create(:ems_openstack))
        api_basic_authorize action_identifier(:host_aggregates, :edit)

        send(request, api_host_aggregate_url(nil, host_aggregate), :params => [:name => 'foo'])

        expected = {
          'success' => true,
          'message' => a_string_including('Updating Host Aggregate'),
          'task_id' => a_kind_of(String)
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end

  describe 'DELETE /api/host_aggregates/:id' do
    it 'deletes a cloud tenant' do
      host_aggregate = FactoryBot.create(:host_aggregate, :ext_management_system => FactoryBot.create(:ems_openstack))

      api_basic_authorize action_identifier(:host_aggregates, :delete, :resource_actions, :delete)

      delete(api_host_aggregate_url(nil, host_aggregate))

      expect(response).to have_http_status(:no_content)
    end
  end
end
