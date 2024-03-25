RSpec.describe "Resource Pools API" do
  context "Resource Pool Queries" do
    before do
      api_basic_authorize action_identifier(:resource_pools, :read, :collection_actions, :get)
      FactoryBot.create(:resource_pool, :name => "ResourcePool1", :type => "ManageIQ::Providers::InfraManager::ResourcePool")
      FactoryBot.create(:resource_pool, :name => "ResourcePool2", :type => "ManageIQ::Providers::CloudManager::ResourcePool")
    end

    it "returns all resource pools by default" do
      get api_resource_pools_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("name" => "resource_pools", "subcount" => 2)
      expect(response.parsed_body["resources"].size).to eq(2)
      response.parsed_body["resources"].each do |resource|
        expect(resource).to include("href")
      end
    end

    it "returns only the requested attributes" do
      get api_resource_pools_url, :params => {:expand => 'resources', :attributes => 'name'}

      expect(response).to have_http_status(:ok)
      response.parsed_body['resources'].each do |resource|
        expect(resource.keys).to match_array(%w[href id name])
      end
    end

    it "supports filtering by type" do
      get api_resource_pools_url, :params => {:type => "ManageIQ::Providers::InfraManager::ResourcePool"}

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["resources"].size).to eq(1)
      expect(response.parsed_body["resources"].first).to include("href")
    end
  end
end
