RSpec.describe 'MetricRollups API' do
  describe 'GET /api/metric_rollups' do
    before do
      FactoryGirl.create(:metric_rollup_vm_hr)
      FactoryGirl.create(:metric_rollup_vm_daily)
      FactoryGirl.create(:metric_rollup_host_daily)
    end

    it 'returns metric_rollups for a specific resource_type' do
      api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

      run_get metric_rollups_url, :resource_type => 'VmOrTemplate', :capture_interval => 'hourly', :start_date => Time.zone.today.to_s

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

      run_get metric_rollups_url, :resource_type    => 'VmOrTemplate',
                                  :resource_ids     => [vm.id],
                                  :capture_interval => 'hourly',
                                  :start_date       => Time.zone.today.to_s

      expected = {
        'count'     => 4,
        'subcount'  => 1,
        'resources' => [
          { 'href' => a_string_including(metric_rollups_url(vm_metric.compressed_id)) }
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

      run_get metric_rollups_url, :resource_type    => 'VmOrTemplate',
                                  :resource_ids     => [vm.id],
                                  :capture_interval => 'daily',
                                  :start_date       => Time.zone.today.to_s

      expected = {
        'count'     => 5,
        'subcount'  => 1,
        'resources' => [
          { 'href' => a_string_including(metric_rollups_url(vm_daily.compressed_id)) }
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires parameters' do
      api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

      run_get metric_rollups_url

      expected = {
        'error' => a_hash_including(
          'message' => 'Must specify resource_type, capture_interval, start_date'
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'restricts hourly metrics' do
      api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

      run_get metric_rollups_url, :resource_type    => 'VmOrTemplate',
                                  :resource_ids     => [],
                                  :capture_interval => 'hourly',
                                  :start_date       => Time.zone.today - 3.months,
                                  :end_date         => Time.zone.today

      expected = {
        'error' => a_hash_including(
          'message' => 'Cannot return hourly rollups for an interval longer than 31 days'
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'does not allow daily records in intervals larger than 24 months' do
      api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

      run_get metric_rollups_url, :resource_type    => 'VmOrTemplate',
                                  :resource_ids     => [],
                                  :capture_interval => 'daily',
                                  :start_date       => (Time.zone.today - 3.years).to_s,
                                  :end_date         => Time.zone.today

      expected = {
        'error' => a_hash_including(
          'message' => 'Cannot return daily rollups for an interval longer than 730 days'
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end
  end
end
