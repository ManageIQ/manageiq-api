RSpec.describe 'Cloud Databases API' do
  include Spec::Support::SupportsHelper

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
      FactoryBot.create(:ems_cloud)
    end

    let(:cloud_database) { FactoryBot.create(:cloud_database_ibm_cloud_vpc, :ext_management_system => ems, :name => "test-db") }

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

    context 'DELETE cloud database' do
      it "deletes the cloud database" do
        api_basic_authorize(resource_action_identifier(:cloud_databases, :delete))

        delete(api_cloud_database_url(nil, cloud_database))
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'PATCH cloud database' do
      it "updates the cloud database name" do
        api_basic_authorize(resource_action_identifier(:cloud_databases, :edit))

        patch(api_cloud_database_url(nil, cloud_database), :params => [{:name => "test-db-updated"}])

        expect_single_action_result(:success => true, :message => /Updating Cloud Database id: #{cloud_database.id} name: '#{cloud_database.name}'/, :task_id => true)
      end
    end

    context 'OPTIONS /cloud_databases' do
      it "returns a DDF schema" do
        stub_supports(ems.class::CloudDatabase, :create)
        stub_params_for(ems.class::CloudDatabase, :create, :fields => [])

        options(api_cloud_databases_url(:ems_id => ems.id))

        expect(response.parsed_body['data']).to match("form_schema" => {"fields" => []})
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
