RSpec.describe "physical_servers API" do
  describe "display a physical server's details" do
    context "with valid properties" do
      it "shows all of its properties" do
        ps = FactoryGirl.create(:physical_server, :ems_ref => "A59D5B36821111E1A9F5E41F13ED4F6A")

        api_basic_authorize action_identifier(:physical_servers, :read, :resource_actions, :get)
        get api_physical_server_url(nil, ps)

        expect_single_resource_query("ems_ref" => "A59D5B36821111E1A9F5E41F13ED4F6A")
      end
    end

    context "without an appropriate role" do
      it "forbids access to read physical server" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize
        get api_physical_server_url(nil, ps)

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end
    end

    context "with valid id" do
      it "returns both id and href" do
        api_basic_authorize(action_identifier(:physical_servers, :read, :resource_actions, :get))
        ps = FactoryGirl.create(:physical_server)

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

        vm = FactoryGirl.create(:vm)
        host = FactoryGirl.create(:host, :vms => [vm])

        asset_details = FactoryGirl.create(:asset_details)

        network = FactoryGirl.create(:network)
        gd1 = FactoryGirl.create(:guest_device, :network => network, :device_type => "ethernet")
        gd2 = FactoryGirl.create(:guest_device, :network => network, :device_type => 'storage')

        firmware = FactoryGirl.create(:firmware)
        hardware = FactoryGirl.create(:hardware, :firmwares => [firmware], :guest_devices => [gd1, gd2])
        network.update_attributes!(:hardware_id => hardware.id.to_s)

        comp_system = FactoryGirl.create(:computer_system, :hardware => hardware)
        ps = FactoryGirl.create(:physical_server, :computer_system => comp_system, :asset_details => asset_details, :host => host)

        get api_physical_server_url(nil, ps), :params => {:attributes => "host,host.vms,asset_details,hardware,hardware.firmwares,hardware.nics,hardware.ports"}

        expected = {
          "host"          => a_hash_including(
            "physical_server_id" => ps.id.to_s,
            "vms"                => [
              a_hash_including("host_id" => host.id.to_s)
            ]
          ),
          "asset_details" => a_hash_including("id" => asset_details.id.to_s),
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
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :power_on, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:power_on))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "powers off a server successfully" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :power_off, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:power_off))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "immediately powers off a server successfully" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :power_off_now, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:power_off_now))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "restarts a server successfully" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :restart, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "immediately restarts a server successfully" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :restart_now, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart_now))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "restarts a server to the system setup successfully" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :restart_to_sys_setup, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart_to_sys_setup))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "restarts a server's management controller" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :restart_mgmt_controller, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart_mgmt_controller))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end
    end

    context "without an appropriate role" do
      it "fails to power on a server" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:power_on))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to power off a server" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:power_off))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to immediately power off a server" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:power_off_now))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to restart a server" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to immediately restart a server" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart_now))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to restart to system setup" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:restart_to_sys_setup))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to restart a server's management controller" do
        ps = FactoryGirl.create(:physical_server)

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
          ps = FactoryGirl.create(:physical_server)
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
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :turn_on_loc_led, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:turn_on_loc_led))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "turns off a location LED successfully" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :turn_off_loc_led, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:turn_off_loc_led))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end

      it "blinks a location LED successfully" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize action_identifier(:physical_servers, :blink_loc_led, :resource_actions, :post)
        post(api_physical_server_url(nil, ps), :params => gen_request(:blink_loc_led))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include("success" => true)
      end
    end

    context "without an appropriate role" do
      it "fails to turn on a location LED" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:turn_on_loc_led))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to turn off a location LED" do
        ps = FactoryGirl.create(:physical_server)

        api_basic_authorize
        post(api_physical_server_url(nil, ps), :params => gen_request(:turn_off_loc_led))

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("kind" => "forbidden")
      end

      it "fails to blink a location LED" do
        ps = FactoryGirl.create(:physical_server)

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
          ps = FactoryGirl.create(:physical_server)
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
        ps = FactoryGirl.create(:physical_server)
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
        ps = FactoryGirl.create(:physical_server)
        api_basic_authorize(action_identifier(:physical_servers, :refresh, :resource_actions, :post))

        post(api_physical_server_url(nil, ps), :params => gen_request(:refresh))

        expect_single_action_result(:success => true, :message => /#{ps.id}.* refreshing/i, :href => api_physical_server_url(nil, ps))
      end

      it "refresh of multiple Physical Servers" do
        ps = FactoryGirl.create(:physical_server)
        ps2 = FactoryGirl.create(:physical_server)
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
end
