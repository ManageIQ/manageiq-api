RSpec.describe "physical_servers API" do
  describe "display a physical server's details" do
    context "with valid properties" do
      it "shows all of its properties" do
        ps = FactoryBot.create(:physical_server, :ems_ref => "A59D5B36821111E1A9F5E41F13ED4F6A")

        api_basic_authorize action_identifier(:physical_servers, :read, :resource_actions, :get)
        get api_physical_server_url(nil, ps)

        expect_single_resource_query("ems_ref" => "A59D5B36821111E1A9F5E41F13ED4F6A")
      end
    end

    context "without an appropriate role" do
      it "forbids access to read physical server" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize
        get api_physical_server_url(nil, ps)

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end
    end

    context "with valid id" do
      it "returns both id and href" do
        api_basic_authorize(action_identifier(:physical_servers, :read, :resource_actions, :get))
        ps = FactoryBot.create(:physical_server)

        get api_physical_server_url(nil, ps)

        expect_single_resource_query("id" => ps.id.to_s, "href" => api_physical_server_url(nil, ps))
      end
    end

    context "with an invalid id" do
      it "fails to retrieve physical server" do
        api_basic_authorize(action_identifier(:physical_servers, :read, :resource_actions, :get))

        get api_physical_server_url(nil, 999_999)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with attribute" do
      it "retrieve details" do
        api_basic_authorize(action_identifier(:physical_servers, :read, :resource_actions, :get))

        vm = FactoryBot.create(:vm)
        host = FactoryBot.create(:host, :vms => [vm])

        asset_detail = FactoryBot.create(:asset_detail)

        network = FactoryBot.create(:network)
        gd1 = FactoryBot.create(:guest_device, :network => network, :device_type => "ethernet")
        gd2 = FactoryBot.create(:guest_device, :network => network, :device_type => 'storage')

        firmware = FactoryBot.create(:firmware)
        hardware = FactoryBot.create(:hardware, :firmwares => [firmware], :guest_devices => [gd1, gd2])
        network.update!(:hardware_id => hardware.id.to_s)

        comp_system = FactoryBot.create(:computer_system, :hardware => hardware)
        ps = FactoryBot.create(:physical_server, :computer_system => comp_system, :asset_detail => asset_detail, :host => host)

        get api_physical_server_url(nil, ps), :params => {:attributes => "host,host.vms,asset_detail,hardware,hardware.firmwares,hardware.nics,hardware.ports"}

        expected = {
          "host"          => a_hash_including(
            "physical_server_id" => ps.id.to_s,
            "vms"                => [
              a_hash_including("host_id" => host.id.to_s)
            ]
          ),
          "asset_detail" => a_hash_including("id" => asset_detail.id.to_s),
          "hardware"      => a_hash_including(
            "id"        => hardware.id.to_s,
            "firmwares" => a_collection_including(
              a_hash_including("resource_id" => hardware.id.to_s)
            ),
            "nics"      => a_collection_including(
              a_hash_including("hardware_id" => hardware.id.to_s)
            ),
            "ports"     => [
              a_hash_including("device_type" => "ethernet")
            ]
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "power on/off a physical server" do
    context "with valid action names" do
      it "powers on a server successfully" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :power_on, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:power_on))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "powers off a server successfully" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :power_off, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:power_off))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "immediately powers off a server successfully" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :power_off_now, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:power_off_now))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "restarts a server successfully" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :restart, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "immediately restarts a server successfully" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :restart_now, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart_now))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "restarts a server to the system setup successfully" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :restart_to_sys_setup, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart_to_sys_setup))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "restarts a server's management controller" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :restart_mgmt_controller, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart_mgmt_controller))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end
    end

    context "without an appropriate role" do
      it "fails to power on a server" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:power_on))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to power off a server" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:power_off))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to immediately power off a server" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:power_off_now))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to restart a server" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to immediately restart a server" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart_now))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to restart to system setup" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart_to_sys_setup))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to restart a server's management controller" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart_mgmt_controller))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end
    end

    context "with a non existent physical server" do
      actions = [
        :power_on,
        :power_off,
        :power_off_now,
        :restart,
        :restart_now,
        :restart_to_sys_setup,
        :restart_mgmt_controller
      ]

      actions.each do |action|
        it "fails to #{action} a server" do
          api_basic_authorize(action_identifier(:physical_servers, action, :resource_actions, :post))

          post(api_physical_server_url(nil, 999_999), :params => gen_request(action))

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "with an existent and a non existent physical server" do
      actions = [
        :power_on,
        :power_off,
        :power_off_now,
        :restart,
        :restart_now,
        :restart_to_sys_setup,
        :restart_mgmt_controller
      ]

      actions.each do |action|
        it "returns status 200 and a failure message for the non existent physical server" do
          ps = FactoryBot.create(:physical_server)
          api_basic_authorize(action_identifier(:physical_servers, action, :resource_actions, :post))

          post(api_physical_servers_url, :params => gen_request(action, [{"href" => api_physical_server_url(nil, ps)}, {"href" => api_physical_server_url(nil, 999_999)}]))

          expected = {
            "results" => a_collection_containing_exactly(
              a_hash_including(
                "message" => a_string_matching(/#{ps.id}/),
                "success" => true,
                "href"    => api_physical_server_url(nil, ps)
              ),
              a_hash_including(
                "message" => a_string_matching(/#{999_999}/),
                "success" => false,
                "href"    => api_physical_server_url(nil, 999_999)
              )
            )
          }
          expect(response.parsed_body).to include(expected)
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "turn on/off a physical server's location LED" do
    context "with valid action names" do
      it "turns on a location LED successfully" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :turn_on_loc_led, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:turn_on_loc_led))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "turns off a location LED successfully" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :turn_off_loc_led, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:turn_off_loc_led))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "blinks a location LED successfully" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :blink_loc_led, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:blink_loc_led))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end
    end

    context "without an appropriate role" do
      it "fails to turn on a location LED" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:turn_on_loc_led))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to turn off a location LED" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:turn_off_loc_led))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to blink a location LED" do
        ps = FactoryBot.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:blink_loc_led))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end
    end

    context "with a non existent physical server" do
      actions = [
        :blink_loc_led,
        :turn_on_loc_led,
        :turn_off_loc_led
      ]

      actions.each do |action|
        it "fails to #{action} a server" do
          api_basic_authorize(action_identifier(:physical_servers, action, :resource_actions, :post))

          post(api_physical_server_url(nil, 999_999), :params => gen_request(action))

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "with an existent and a non existent physical server" do
      actions = [
        :blink_loc_led,
        :turn_on_loc_led,
        :turn_off_loc_led
      ]

      actions.each do |action|
        it "for the action #{action} returns status 200 and a failure message for the non existent physical server" do
          ps = FactoryBot.create(:physical_server)
          api_basic_authorize(action_identifier(:physical_servers, action, :resource_actions, :post))

          post(api_physical_servers_url, :params => gen_request(action, [{"href" => api_physical_server_url(nil, ps)}, {"href" => api_physical_server_url(nil, 999_999)}]))

          expected = {
            "results" => a_collection_containing_exactly(
              a_hash_including(
                "message" => a_string_matching(/#{ps.id}/),
                "success" => true,
                "href"    => api_physical_server_url(nil, ps)
              ),
              a_hash_including(
                "message" => a_string_matching(/#{999_999}/),
                "success" => false,
                "href"    => api_physical_server_url(nil, 999_999)
              )
            )
          }
          expect(response.parsed_body).to include(expected)
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "Physical Server refresh action" do
    context "with an invalid id" do
      it "it responds with 404 Not Found" do
        api_basic_authorize(action_identifier(:physical_servers, :refresh, :resource_actions, :post))

        post(api_physical_server_url(nil, 999_999), :params => gen_request(:refresh))

        expect(response).to have_http_status(:not_found)
      end
    end

    context "without an appropriate role" do
      it "it responds with 403 Forbidden" do
        ps = FactoryBot.create(:physical_server)
        api_basic_authorize

        post(api_physical_server_url(nil, ps), :params => gen_request(:refresh))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an appropriate role" do
      it "rejects refresh for unspecified physical servers" do
        api_basic_authorize(action_identifier(:physical_servers, :refresh, :resource_actions, :post))

        post(api_physical_servers_url, :params => gen_request(:refresh, [{"href" => "/api/physical_servers/"}, {"href" => "/api/physical_servers/"}]))

        expect_bad_request(/Must specify an id/i)
      end

      it "refresh of a single Physical Server" do
        ps = FactoryBot.create(:physical_server)
        api_basic_authorize(action_identifier(:physical_servers, :refresh, :resource_actions, :post))

        post(api_physical_server_url(nil, ps), :params => gen_request(:refresh))

        expect_single_action_result(:success => true, :message => /#{ps.id}.* refreshing/i, :href => api_physical_server_url(nil, ps))
      end

      it "refresh of multiple Physical Servers" do
        ps = FactoryBot.create(:physical_server)
        ps2 = FactoryBot.create(:physical_server)
        api_basic_authorize(action_identifier(:physical_servers, :refresh, :resource_actions, :post))

        post(api_physical_servers_url, :params => gen_request(:refresh, [{"href" => api_physical_server_url(nil, ps)}, {"href" => api_physical_server_url(nil, ps2)}]))

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(
              "message" => a_string_matching(/#{ps.id}.* refreshing/i),
              "success" => true,
              "href"    => api_physical_server_url(nil, ps)
            ),
            a_hash_including(
              "message" => a_string_matching(/#{ps2.id}.* refreshing/i),
              "success" => true,
              "href"    => api_physical_server_url(nil, ps2)
            )
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Apply config pattern action" do
    let(:config_pattern) { FactoryBot.create(:customization_script) }
    let(:config_pattern2) { FactoryBot.create(:customization_script) }
    let(:ps) { FactoryBot.create(:physical_server) }
    let(:href_ps) { api_physical_server_url(nil, ps) }
    let(:ps2) { FactoryBot.create(:physical_server) }
    let(:href_ps2) { api_physical_server_url(nil, ps2) }

    context "with an invalid physical server id and a valid config pattern id" do
      it "it responds with 404 Not Found" do
        api_basic_authorize(action_identifier(:physical_servers, :apply_config_pattern, :resource_actions, :post))

        post(api_physical_server_url(nil, 999_999), :params => gen_request(:apply_config_pattern, "pattern_id" => config_pattern.id, "uuid" => 999_999))

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a valid physical server id and an invalid config pattern id" do
      it "it responds with 404 Not Found" do
        api_basic_authorize(action_identifier(:physical_servers, :apply_config_pattern, :resource_actions, :post))

        post(api_physical_server_url(nil, ps), :params => gen_request(:apply_config_pattern, "pattern_id" => 999_999, "uuid" => ps.ems_ref))

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["error"]).to include("message" => "customization_scripts with id:999999 not found")
      end

      it "apply config pattern of multiple Physical servers" do
        api_basic_authorize(action_identifier(:physical_servers, :apply_config_pattern, :resource_actions, :post))

        resources = [
          {"pattern_id" => config_pattern.id, "uuid" => ps.ems_ref, "href" => href_ps},
          {"pattern_id" => 999_999, "uuid" => ps2.ems_ref, "href" => href_ps2}
        ]

        post(api_physical_servers_url, :params => gen_request(:apply_config_pattern, resources))

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(
              "success" => true,
              "href"    => href_ps
            ),
            a_hash_including(
              "success" => false,
              "message" => "customization_scripts with id:999999 not found"
            )
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with a valid physical server id and config pattern id" do
      it "apply config pattern of a single Physical server" do
        api_basic_authorize(action_identifier(:physical_servers, :apply_config_pattern, :resource_actions, :post))

        post(api_physical_server_url(nil, ps), :params => gen_request(:apply_config_pattern, "pattern_id" => config_pattern.id, "uuid" => ps.ems_ref))

        expect_single_action_result(:success => true, :href => api_physical_server_url(nil, ps))
      end

      it "apply config pattern of multiple Physical servers" do
        api_basic_authorize(action_identifier(:physical_servers, :apply_config_pattern, :resource_actions, :post))

        resources = [
          {"pattern_id" => config_pattern.id, "uuid" => ps.ems_ref, "href" => href_ps},
          {"pattern_id" => config_pattern2.id, "uuid" => ps2.ems_ref, "href" => href_ps2}
        ]

        post(api_physical_servers_url, :params => gen_request(:apply_config_pattern, resources))

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(
              "success" => true,
              "href"    => href_ps
            ),
            a_hash_including(
              "success" => true,
              "href"    => href_ps2
            )
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end
  end
  describe "Subcollections" do
    let(:physical_server) { FactoryBot.create(:physical_server) }
    let(:event_stream) { FactoryBot.create(:event_stream, :physical_server_id => physical_server.id, :event_type => "Some Event") }

    context 'Events subcollection' do
      context 'GET /api/physical_servers/:id/event_streams' do
        it 'returns the event_streams with an appropriate role' do
          api_basic_authorize(collection_action_identifier(:event_streams, :read, :get))

          expected = {
            'resources' => [
              { 'href' => api_physical_server_event_stream_url(nil, physical_server, event_stream) }
            ]
          }
          get(api_physical_server_event_streams_url(nil, physical_server))

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(expected)
        end

        it 'does not return the event_streams without an appropriate role' do
          api_basic_authorize
          get(api_physical_server_event_streams_url(nil, physical_server))

          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'GET /api/physical_servers/:id/event_streams/:id' do
        it 'returns the event_stream with an appropriate role' do
          api_basic_authorize(action_identifier(:event_streams, :read, :resource_actions, :get))
          url = api_physical_server_event_stream_url(nil, physical_server, event_stream)
          expected = { 'href' => url }
          get(url)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(expected)
        end

        it 'does not return the event_stream without an appropriate role' do
          api_basic_authorize
          get(api_physical_server_event_stream_url(nil, physical_server, event_stream))

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    describe 'FirmwareBinaries subcollection' do
      let(:physical_server) { FactoryBot.create(:physical_server, :with_asset_detail) }
      let(:firmware_binary) { FactoryBot.create(:firmware_binary) }
      let!(:firmware_target) do
        FactoryBot.create(
          :firmware_target,
          :manufacturer      => physical_server.asset_detail.manufacturer,
          :model             => physical_server.asset_detail.model,
          :firmware_binaries => [firmware_binary]
        )
      end

      describe 'GET /api/physical_servers/:id/firmware_binaries' do
        let(:url) { api_physical_server_firmware_binaries_url(nil, physical_server) }

        it 'returns the firmware_binaries with an appropriate role' do
          api_basic_authorize subcollection_action_identifier(:physical_servers, :firmware_binaries, :read, :get)
          get(url)
          expect_result_resources_to_include_hrefs(
            'resources',
            [
              api_physical_server_firmware_binary_url(nil, physical_server, firmware_binary)
            ]
          )
          expect(response).to have_http_status(:ok)
        end

        it 'does not return the event_streams without an appropriate role' do
          api_basic_authorize
          get(url)
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
