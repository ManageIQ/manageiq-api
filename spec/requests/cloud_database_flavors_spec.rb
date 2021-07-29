RSpec.describe 'Cloud Database Flavors API' do
  context 'cloud database flavors index' do
    it 'rejects request without appropriate role' do
      api_basic_authorize

      get api_cloud_database_flavors_url

      expect(response).to have_http_status(:forbidden)
    end

    it 'can list cloud database flavors' do
      FactoryBot.create_list(:cloud_database_flavor, 2)
      api_basic_authorize collection_action_identifier(:cloud_database_flavors, :read, :get)

      get api_cloud_database_flavors_url

      expect_query_result(:cloud_database_flavors, 2)
      expect(response).to have_http_status(:ok)
    end
  end
end
