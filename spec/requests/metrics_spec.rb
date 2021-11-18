RSpec.describe 'Metrics API' do
  describe 'GET /api/metrics' do
    before do
      FactoryBot.create(:metric_vm_rt)
      FactoryBot.create(:metric_host_rt)
      FactoryBot.create(:metric_container_node_rt)
    end

    it 'returns metrics for a specific resource_type' do
      api_basic_authorize collection_action_identifier(:metrics, :read, :get)

      get(api_metrics_url, :params => {:resource_type => 'VmOrTemplate', :start_date => Time.zone.today.to_s})

      expected = {
        'count'    => 3,
        'subcount' => 1
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'returns metrics for specific resources' do
      vm = FactoryBot.create(:vm_or_template)
      vm_metric = FactoryBot.create(:metric_vm_rt, :resource => vm)
      api_basic_authorize collection_action_identifier(:metrics, :read, :get)

      get(
        api_metrics_url,
        :params => {
          :resource_type => 'VmOrTemplate',
          :resource_ids  => [vm.id],
          :start_date    => Time.zone.today.to_s
        }
      )

      expected = {
        'count'     => 4,
        'subcount'  => 1,
        'resources' => [
          {'href' => a_string_including(api_metric_url(nil, vm_metric))}
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    let(:today)     { Time.zone.today }
    let(:tomorrow)  { today + 1.day }
    let(:next_week) { today + 7.days }

    it 'returns metrics between specific dates' do
      vm = FactoryBot.create(:vm_or_template)
      vm_metric = FactoryBot.create(:metric_vm_rt, :resource => vm)
      FactoryBot.create(:metric_vm_rt, :resource => vm, :timestamp => next_week)

      api_basic_authorize collection_action_identifier(:metrics, :read, :get)

      get(
        api_metrics_url,
        :params => {
          :resource_type => 'VmOrTemplate',
          :resource_ids  => [vm.id],
          :start_date    => today.to_s,
          :end_date      => tomorrow.to_s,
        }
      )

      expected = {
        'count'     => 5,
        'subcount'  => 1,
        'resources' => [
          {'href' => a_string_including(api_metric_url(nil, vm_metric))}
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires parameters' do
      api_basic_authorize collection_action_identifier(:metrics, :read, :get)

      get api_metrics_url

      expected = {
        'error' => a_hash_including(
          'message' => 'Must specify resource_type, start_date'
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'pages the request by default' do
      api_basic_authorize collection_action_identifier(:metrics, :read, :get)

      get(
        api_metrics_url,
        :params => {
          :resource_type    => 'VmOrTemplate',
          :capture_interval => 'daily',
          :start_date       => Time.zone.today.to_s
        }
      )
      expected = {
        'count'          => 3,
        'subcount'       => 1,
        'subquery_count' => 1,
        'pages'          => 1
      }
      expect(response.parsed_body).to include(expected)
      expect(response.parsed_body['links'].keys).to match_array(%w[self first last])
    end

    it 'can override the default limit' do
      vm = FactoryBot.create(:vm_or_template)
      FactoryBot.create_list(:metric_vm_rt, 3, :resource => vm)
      api_basic_authorize collection_action_identifier(:metrics, :read, :get)

      get(
        api_metrics_url,
        :params => {
          :resource_type    => 'VmOrTemplate',
          :resource_ids     => [vm.id],
          :capture_interval => 'hourly',
          :start_date       => Time.zone.today.to_s,
          :limit            => 1
        }
      )

      expected = {
        'count'          => 6,
        'subcount'       => 1,
        'subquery_count' => 3,
        'pages'          => 3
      }
      expect(response.parsed_body).to include(expected)
      expect(response.parsed_body['links'].keys).to match_array(%w[self next first last])
    end
  end
end
