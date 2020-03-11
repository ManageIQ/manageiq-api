RSpec.describe 'Clusters API' do
  context 'OPTIONS /api/clusters' do
    it 'returns clusters node_types' do
      expected_data = {"node_types" => "mixed_clusters"}

      options(api_clusters_url)
      expect_options_results(:clusters, expected_data)
    end
  end
end
