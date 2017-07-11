RSpec.describe 'MetricRollups API' do
  describe 'GET /api/metric_rollups' do
    before do
      FactoryGirl.create(:metric_rollup_vm_hr)
      FactoryGirl.create(:metric_rollup_vm_daily)
      FactoryGirl.create(:metric_rollup_host_daily)
    end

    context 'no parameters' do
      it 'returns all metric_rollups' do
        api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

        run_get(metric_rollups_url)

        expected = {
          'name'     => 'metric_rollups',
          'count'    => 3,
          'subcount' => 3
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end

    context 'parameters' do
      it 'returns metric_rollups for a specific resource_type' do
        api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

        run_get metric_rollups_url, :resource_type => 'VmOrTemplate'

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

        run_get metric_rollups_url, :resource_type => 'VmOrTemplate', :resource_ids => [vm.id]

        expected = {
          'count'     => 4,
          'subcount'  => 1,
          'resources' => [
            a_hash_including('id' => vm_metric.compressed_id, 'resource_id' => vm.compressed_id)
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

        run_get metric_rollups_url, :resource_type => 'VmOrTemplate', :resource_ids => [vm.id], :capture_interval => 'daily'

        expected = {
          'count'     => 5,
          'subcount'  => 1,
          'resources' => [
            a_hash_including('id' => vm_daily.compressed_id, 'resource_id' => vm.compressed_id)
          ]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end

  describe 'GET /api/metric_rollups/:id' do
    it 'returns a metric rollup' do
      vm_hr = FactoryGirl.create(:metric_rollup_vm_hr)
      api_basic_authorize collection_action_identifier(:metric_rollups, :read, :get)

      run_get(metric_rollups_url(vm_hr.id))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => vm_hr.compressed_id)
    end
  end
end
