RSpec.describe 'MetricRollups API' do
  describe 'GET /api/metric_rollups' do
    before do
      FactoryGirl.create(:metric_rollup_vm_hr)
      FactoryGirl.create(:metric_rollup_vm_daily)
      FactoryGirl.create(:metric_rollup_host_daily)
    end

    it 'returns metric_rollups for a specific resource_type' do
      api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

      run_get api_metric_rollups_url, :resource_type => 'VmOrTemplate', :capture_interval => 'hourly', :start_date => Time.zone.today.to_s

      expected = {
        'count'    => 3,
        'subcount' => 1
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'returns metric_rollups for specific resources' do
      vm = FactoryGirl.create(:vm_or_template)
      vm_metric = FactoryGirl.create(:metric_rollup_vm_hr, :resource => vm)
      api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

      run_get api_metric_rollups_url, :resource_type    => 'VmOrTemplate',
                                  :resource_ids     => [vm.id],
                                  :capture_interval => 'hourly',
                                  :start_date       => Time.zone.today.to_s

      expected = {
        'count'     => 4,
        'subcount'  => 1,
        'resources' => [
          { 'href' => a_string_including(api_metric_rollup_url(nil, vm_metric.compressed_id)) }
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'returns metric_rollups for specific resources and capture interval times' do
      vm = FactoryGirl.create(:vm_or_template)
      FactoryGirl.create(:metric_rollup_vm_hr, :resource => vm)
      vm_daily = FactoryGirl.create(:metric_rollup_vm_daily, :resource => vm)
      api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

      run_get api_metric_rollups_url, :resource_type    => 'VmOrTemplate',
                                  :resource_ids     => [vm.id],
                                  :capture_interval => 'daily',
                                  :start_date       => Time.zone.today.to_s

      expected = {
        'count'     => 5,
        'subcount'  => 1,
        'resources' => [
          { 'href' => a_string_including(api_metric_rollup_url(nil, vm_daily.compressed_id)) }
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires parameters' do
      api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

      run_get api_metric_rollups_url

      expected = {
        'error' => a_hash_including(
          'message' => 'Must specify resource_type, capture_interval, start_date'
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'pages the request by default' do
      api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

      run_get api_metric_rollups_url, :resource_type    => 'VmOrTemplate',
                                  :capture_interval => 'daily',
                                  :start_date       => Time.zone.today.to_s
      expected = {
        'count'          => 3,
        'subcount'       => 1,
        'subquery_count' => 1,
        'pages'          => 1
      }
      expect(response.parsed_body).to include(expected)
      expect(response.parsed_body['links'].keys).to match_array(%w(self first last))
    end

    it 'validates that the capture interval is valid' do
      api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

      run_get api_metric_rollups_url, :resource_type    => 'VmOrTemplate',
                                  :start_date       => Time.zone.today.to_s,
                                  :capture_interval => 'bad_interval'

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => a_string_including('Capture interval must be one of')
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'can override the default limit' do
      vm = FactoryGirl.create(:vm_or_template)
      FactoryGirl.create_list(:metric_rollup_vm_hr, 3, :resource => vm)
      api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

      run_get api_metric_rollups_url, :resource_type    => 'VmOrTemplate',
                                  :resource_ids     => [vm.id],
                                  :capture_interval => 'hourly',
                                  :start_date       => Time.zone.today.to_s,
                                  :limit            => 1

      expected = {
        'count'          => 6,
        'subcount'       => 1,
        'subquery_count' => 3,
        'pages'          => 3
      }
      expect(response.parsed_body).to include(expected)
      expect(response.parsed_body['links'].keys).to match_array(%w(self next first last))
    end
  end
end
