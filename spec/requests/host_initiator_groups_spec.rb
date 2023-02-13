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

  it "deletes a single Host Initiator Group" do
    provider = FactoryBot.create(:ems_autosde, :name => 'Autosde')
    host_initiator_group = FactoryBot.create("ManageIQ::Providers::Autosde::StorageManager::HostInitiatorGroup", :name => 'test_host_initiator_group', :ext_management_system => provider)
    api_basic_authorize('host_initiator_group_delete')

    stub_supports(HostInitiatorGroup, :delete)
    post(api_host_initiator_group_url(nil, host_initiator_group), :params => gen_request(:delete))

    expect_single_action_result(:success => true, :message => /Deleting Host Initiator Group id: #{host_initiator_group.id} name: '#{host_initiator_group.name}'/)
  end

  it "deletes multiple Host Initiator Groups" do
    provider = FactoryBot.create(:ems_autosde, :name => 'Autosde')
    host_initiator_group1 = FactoryBot.create("ManageIQ::Providers::Autosde::StorageManager::HostInitiatorGroup", :name => 'test_host_initiator_group1', :ext_management_system => provider)
    host_initiator_group2 = FactoryBot.create("ManageIQ::Providers::Autosde::StorageManager::HostInitiatorGroup", :name => 'test_host_initiator_group2', :ext_management_system => provider)
    api_basic_authorize('host_initiator_group_delete')

    stub_supports(HostInitiatorGroup, :delete)
    post(api_host_initiator_groups_url, :params => gen_request(:delete, [{"href" => api_host_initiator_group_url(nil, host_initiator_group1)}, {"href" => api_host_initiator_group_url(nil, host_initiator_group2)}]))

    results = response.parsed_body["results"]

    expect(results[0]["message"]).to match(/Deleting Host Initiator Group id: #{host_initiator_group1.id} name: '#{host_initiator_group1.name}'/)
    expect(results[0]["success"]).to match(true)
    expect(results[1]["message"]).to match(/Deleting Host Initiator Group id: #{host_initiator_group2.id} name: '#{host_initiator_group2.name}'/)
    expect(results[1]["success"]).to match(true)

    expect(response).to have_http_status(:ok)
  end
end
