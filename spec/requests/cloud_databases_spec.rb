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

  describe 'cloud database actions' do
    let(:ems) do
      FactoryBot.create(:ems_amazon)
    end

    context 'POST cloud database' do
      it "creates the cloud database" do
        api_basic_authorize collection_action_identifier(:cloud_databases, :create)

        submit_data = {
          :name     => "test-db",
          :ems_id   => ems.id,
          :flavor   => "db.t2.micro",
          :storage  => 5,
          :database => "mysql",
          :username => "test123",
          :password => "test456"
        }
        post(api_cloud_databases_url, :params => submit_data)

        expected = {
          'results' => [
            a_hash_including(
              "success"   => true,
              "message"   => "Creating Cloud Database #{submit_data[:name]} for Provider #{ems.name}",
              "task_id"   => anything,
              "task_href" => a_string_matching(api_tasks_url)
            )
          ]
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
