#
# REST API Request Tests - /api/settings
#
describe "Settings API" do
  let(:api_settings) { Api::ApiConfig.collections[:settings][:categories] }
  let(:server) { FactoryGirl.create(:miq_server) }
  let(:super_admin) { FactoryGirl.create(:user, :role => 'super_administrator', :userid => 'alice', :password => 'alicepassword') }

  context "Settings Update" do
    it "updates to settings return a BadRequestError upon failed validation" do
      api_basic_authorize(:user => super_admin.userid, :password => super_admin.password)

      patch(api_server_settings_url(nil, server), :params => {:authentication => {:mode => "bogus_auth_mode"}})

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => a_string_including('Settings validation failed - ')
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "Settings Queries" do
    it "tests queries of all exposed settings" do
      api_basic_authorize action_identifier(:settings, :read, :collection_actions, :get)

      get api_settings_url

      expect_result_to_have_only_keys(api_settings)
    end

    it "tests query for a specific setting category" do
      api_basic_authorize action_identifier(:settings, :read, :resource_actions, :get)

      category = api_settings.first
      get api_setting_url(nil, category)

      expect_result_to_have_only_keys(category)
    end

    it "tests that query for a specific setting category matches the Settings hash" do
      api_basic_authorize action_identifier(:settings, :read, :resource_actions, :get)

      category = api_settings.first
      get api_setting_url(nil, category)

      expect(response.parsed_body[category]).to eq(Settings[category].to_hash.stringify_keys)
    end

    it "rejects query for an invalid setting category " do
      api_basic_authorize action_identifier(:settings, :read, :resource_actions, :get)

      get api_setting_url(nil, "invalid_setting")

      expect(response).to have_http_status(:not_found)
    end
  end

  context "Fine-Grained Settings Queries" do
    let(:sample_settings) do
      JSON.parse('{
        "product": {
          "maindb": "ExtManagementSystem",
          "container_deployment_wizard": false,
          "datawarehouse_manager": false
        },
        "server": {
          "role": "database_operations,event,reporting,scheduler,smartstate,ems_operations,ems_inventory,user_interface,websocket,web_services,automate",
          "worker_monitor": {
            "kill_algorithm": {
              "name": "used_swap_percent_gt_value",
              "value": 80
            },
            "miq_server_time_threshold": "2.minutes",
            "nice_delta": 1,
            "poll": "2.seconds",
            "sync_interval": "30.minutes",
            "wait_for_started_timeout": "10.minutes"
          }
        },
        "authentication": {
          "bind_timeout": 30,
          "follow_referrals": false,
          "get_direct_groups": true,
          "group_memberships_max_depth": 2,
          "ldapport": "389",
          "mode": "database",
          "search_timeout": 30,
          "user_type": "userprincipalname"
        }
      }')
    end

    def stub_api_settings_categories(value)
      settings_config = Api::ApiConfig.collections["settings"].dup
      settings_config["categories"] = value
      allow(Api::ApiConfig.collections).to receive("settings") { settings_config }
    end

    before do
      stub_settings_merge(sample_settings)
    end

    it "supports multiple categories" do
      stub_api_settings_categories(%w(product authentication server))
      api_basic_authorize action_identifier(:settings, :read, :resource_actions, :get)

      get api_settings_url

      expect(response.parsed_body).to match(
        "product"        => sample_settings["product"],
        "authentication" => sample_settings["authentication"],
        "server"         => sample_settings["server"]
      )
    end

    it "supports partial categories" do
      stub_api_settings_categories(%w(product server/role))
      api_basic_authorize action_identifier(:settings, :read, :resource_actions, :get)

      get api_settings_url

      expect(response.parsed_body).to match(
        "product" => sample_settings["product"],
        "server"  => { "role" => sample_settings["server"]["role"] }
      )
    end

    it "supports second level partial categories" do
      stub_api_settings_categories(%w(product server/role server/worker_monitor/sync_interval))
      api_basic_authorize action_identifier(:settings, :read, :resource_actions, :get)

      get api_settings_url

      expect(response.parsed_body).to match(
        "product" => sample_settings["product"],
        "server"  => {
          "role"           => sample_settings["server"]["role"],
          "worker_monitor" => { "sync_interval" => sample_settings["server"]["worker_monitor"]["sync_interval"] }
        }
      )
    end

    it "supports multiple and partial categories" do
      stub_api_settings_categories(%w(product server/role server/worker_monitor authentication))
      api_basic_authorize action_identifier(:settings, :read, :resource_actions, :get)

      get api_settings_url

      expect(response.parsed_body).to match(
        "product"        => sample_settings["product"],
        "server"         => {
          "role"           => sample_settings["server"]["role"],
          "worker_monitor" => sample_settings["server"]["worker_monitor"],
        },
        "authentication" => sample_settings["authentication"]
      )
    end
  end
end
