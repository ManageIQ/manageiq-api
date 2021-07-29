RSpec.describe 'Cloud Databases API' do
  context 'cloud databases index' do
    it 'rejects request without appropriate role' do
      api_basic_authorize

      get api_cloud_databases_url

      expect(response).to have_http_status(:forbidden)
    end

    it 'can list cloud databases' do
      FactoryBot.create_list(:cloud_database, 2)
      api_basic_authorize collection_action_identifier(:cloud_databases, :read, :get)

      get api_cloud_databases_url

      expect_query_result(:cloud_databases, 2)
      expect(response).to have_http_status(:ok)
    end
  end
end
