describe "Host Initiator Groups API" do
  include Spec::Support::SupportsHelper
  context "POST /api/host_initiator_groups" do
    it "with an invalid ems_id it responds with 404 Not Found" do
      api_basic_authorize(collection_action_identifier(:host_initiator_groups, :create))

      request = {
        "action"   => "create",
        "resource" => {
          "ems_id"              => nil,
          "name"                => "test_host_initiator_group",
          "physical_storage_id" => "1",
        }
      }

      post(api_host_initiator_groups_url, :params => request)

      expect(response).to have_http_status(:bad_request)
    end

    it "creates new Host Initiator Group" do
      api_basic_authorize(collection_action_identifier(:host_initiator_groups, :create))
      provider = FactoryBot.create(:ems_autosde, :name => 'Autosde')
      request = {
        "action"   => "create",
        "resource" => {
          "ems_id"              => provider.id,
          "name"                => "test_host_initiator_group",
          "physical_storage_id" => provider.id.to_s,
        }
      }

      post(api_host_initiator_groups_url, :params => request)

      expect_multiple_action_result(1, :success => true, :message => /Creating Host Initiator Group test_host_initiator_group for Provider #{provider.name}/, :task => true)
    end

    it "Refuses to create without appropriate role" do
      api_basic_authorize
      provider = FactoryBot.create(:ems_autosde, :name => 'Autosde')
      request = {
        "action"   => "create",
        "resource" => {
          "ems_id"              => provider.id,
          "name"                => "test_host_initiator_group",
          "physical_storage_id" => provider.id.to_s,
        }
      }

      post(api_host_initiator_groups_url, :params => request)
      expect(response).to have_http_status(:forbidden)
    end

    it "Won't create for unsupported models" do
      api_basic_authorize(collection_action_identifier(:host_initiator_groups, :create))
      provider = FactoryBot.create(:ems_autosde, :name => 'Autosde')

      stub_supports_not(ManageIQ::Providers::Autosde::StorageManager::HostInitiatorGroup, :create)

      request = {
        "action"   => "create",
        "resource" => {
          "ems_id"              => provider.id,
          "name"                => "test_host_initiator_group",
          "physical_storage_id" => provider.id.to_s,
        }
      }

      post(api_host_initiator_groups_url, :params => request)

      expect(response).to have_http_status(:bad_request)
    end
  end
end
