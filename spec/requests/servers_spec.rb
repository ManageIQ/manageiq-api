RSpec.describe "Servers" do
  let(:server) { FactoryBot.create(:miq_server) }

  describe "/api/servers" do
    it "does not allow an unauthorized user to list the servers" do
      expect_forbidden_request { get(api_servers_url) }
    end
  end

  context "get", :get do
    it "allows GETs of a server" do
      api_basic_authorize action_identifier(:servers, :read, :resource_actions, :get)

      get(api_server_url(nil, server))

      expect_single_resource_query(
        "href" => api_server_url(nil, server),
        "id"   => server.id.to_s
      )
    end
  end

  context "edit", :edit do
    it "can update a server with POST" do
      api_basic_authorize action_identifier(:servers, :edit)

      server = FactoryBot.create(:miq_server, :name => "Current Server name")

      post(api_server_url(nil, server), :params => gen_request(:edit, :name => "New Server name"))

      expect(response).to have_http_status(:ok)
      server.reload
      expect(server.name).to eq("New Server name")
    end

    it "will fail if you try to edit forbidden fields" do
      api_basic_authorize action_identifier(:servers, :edit)

      server = FactoryBot.create(:miq_server, :name => "Current Server name")

      post(api_server_url(nil, server), :params => gen_request(:edit, :started_on => Time.now.utc))
      expect_bad_request("Attribute(s) 'started_on' should not be specified for updating a server resource")

      post(api_server_url(nil, server), :params => gen_request(:edit, :stopped_on => Time.now.utc))
      expect_bad_request("Attribute(s) 'stopped_on' should not be specified for updating a server resource")
    end

    it "can update multiple servers with POST" do
      api_basic_authorize action_identifier(:servers, :edit)

      server1 = FactoryBot.create(:miq_server, :name => "Test Server 1")
      server2 = FactoryBot.create(:miq_server, :name => "Test Server 2")

      options = [
        {"href" => api_server_url(nil, server1), "name" => "Updated Test Server 1"},
        {"href" => api_server_url(nil, server2), "name" => "Updated Test Server 2"}
      ]

      post(api_servers_url, :params => gen_request(:edit, options))

      expect(response).to have_http_status(:ok)

      expect_results_to_match_hash(
        "results",
        [
          {"id" => server1.id.to_s, "name" => "Updated Test Server 1"},
          {"id" => server2.id.to_s, "name" => "Updated Test Server 2"}
        ]
      )

      expect(server1.reload.name).to eq("Updated Test Server 1")
      expect(server2.reload.name).to eq("Updated Test Server 2")
    end

    it "will fail to update multiple servers if any invalid fields are edited" do
      api_basic_authorize action_identifier(:servers, :edit)

      server1 = FactoryBot.create(:miq_server, :name => "Test Server 1")
      server2 = FactoryBot.create(:miq_server, :name => "Test Server 2")

      options = [
        {"href" => api_server_url(nil, server1), "percent_memory" => 27},
        {"href" => api_server_url(nil, server2), "started_on" => Time.now.utc}
      ]

      post(api_servers_url, :params => gen_request(:edit, options))

      expect_bad_request("Attribute(s) 'percent_memory' should not be specified for updating a server resource")
    end

    it "forbids edit of a server without an appropriate role" do
      expect_forbidden_request do
        server = FactoryBot.create(:miq_server, :name => "Current Server name")
        post(api_server_url(nil, server), :params => gen_request(:edit, :name => "New Server name"))
      end
    end
  end

  context "delete", :delete do
    it "can delete a server with POST if the server is deletable" do
      api_basic_authorize action_identifier(:servers, :delete)
      server = FactoryBot.create(:miq_server, :status => 'stopped')

      expect { post(api_server_url(nil, server), :params => gen_request(:delete)) }.to change(MiqServer, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end

    it "will not delete a server with POST if the server is not deletable" do
      api_basic_authorize action_identifier(:servers, :delete)
      server = FactoryBot.create(:miq_server, :status => 'started')

      expect { post(api_server_url(nil, server), :params => gen_request(:delete)) }.to change(MiqServer, :count).by(0)
      expect_single_action_result(:success => false, :message => 'Failed to destroy the record')
    end

    it "can delete a server with DELETE if the server is deletable" do
      api_basic_authorize action_identifier(:servers, :delete)
      server = FactoryBot.create(:miq_server, :status => 'stopped')

      expect { delete(api_server_url(nil, server)) }.to change(MiqServer, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "will not delete a server with DELETE if the server is not deletable" do
      api_basic_authorize action_identifier(:servers, :delete)
      server = FactoryBot.create(:miq_server, :status => 'started')

      expect { delete(api_server_url(nil, server)) }.to change(MiqServer, :count).by(0)
    end

    it "can delete multiple servers with POST if the servers are deletable" do
      api_basic_authorize action_identifier(:servers, :delete)
      servers = FactoryBot.create_list(:miq_server, 2, :status => 'stopped')

      options = [
        {"href" => api_server_url(nil, servers.first)},
        {"href" => api_server_url(nil, servers.last)}
      ]

      expect { post(api_servers_url, :params => gen_request(:delete, options)) }.to change(MiqServer, :count).by(-2)
      expect(response).to have_http_status(:ok)
    end

    it "forbids deletion of a server without an appropriate role" do
      expect_forbidden_request do
        server = FactoryBot.create(:miq_server, :name => "Current Server name")
        delete(api_server_url(nil, server))
      end
    end
  end

  describe "/api/servers/:id?expand=settings", :settings do
    it "expands the settings subcollection" do
      api_basic_authorize(:ops_settings, :ops_diagnostics)

      get(api_server_url(nil, server), :params => {:expand => 'settings'})

      expect(response.parsed_body).to include('settings' => a_kind_of(Hash))
      expect(response).to have_http_status(:ok)
    end

    it "does not expand settings without an appropriate role" do
      api_basic_authorize

      get(api_server_url(nil, server), :params => {:expand => 'settings'})

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "/api/servers/:id/settings", :settings do
    let(:original_timeout) { server.settings_for_resource[:api][:authentication_timeout] }
    let(:super_admin) { FactoryBot.create(:user, :role => 'super_administrator', :userid => 'alice', :password => 'alicepassword') }


    it "shows the settings to an authenticated user with the proper role" do
      api_basic_authorize(:ops_settings)

      get(api_server_settings_url(nil, server))

      expect(response).to have_http_status(:ok)
    end

    it "does not allow an authenticated user who doesn't have the proper role to view the settings" do
      api_basic_authorize

      get(api_server_settings_url(nil, server))

      expect(response).to have_http_status(:forbidden)
    end

    it "does not allow an unauthenticated user to view the settings" do
      get(api_server_settings_url(nil, server))

      expect(response).to have_http_status(:unauthorized)
    end

    it "permits updates to settings for an authenticated super-admin user" do
      api_basic_authorize(:user => super_admin.userid, :password => super_admin.password)

      expect {
        patch(api_server_settings_url(nil, server), :params => {:api => {:authentication_timeout => "1337.minutes"}})
      }.to change { server.settings_for_resource[:api][:authentication_timeout] }.from(original_timeout).to("1337.minutes")

      expect(response.parsed_body).to include("api" => a_hash_including("authentication_timeout" => "1337.minutes"))
      expect(response).to have_http_status(:ok)
    end

    it "does not allow an authenticated non-super-admin user to update settings" do
      api_basic_authorize

      expect {
        patch(api_server_settings_url(nil, server), :params => {:api => {:authentication_timeout => "10.minutes"}})
      }.not_to change { server.settings_for_resource[:api][:authentication_timeout] }

      expect(response).to have_http_status(:forbidden)
    end

    it "does not allow an unauthenticated user to update the settings" do
      expect {
        patch(api_server_settings_url(nil, server), :params => {:api => {:authentication_timeout => "10.minutes"}})
      }.not_to change { server.settings_for_resource[:api][:authentication_timeout] }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns a bad_request to an update if the settings validation failed" do
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

    context "with an existing settings change" do
      before do
        server.add_settings_for_resource("api" => {"authentication_timeout" => "7331.minutes"})
      end

      it "allows an authenticated super-admin user to delete settings" do
        api_basic_authorize(:user => super_admin.userid, :password => super_admin.password)
        expect(server.settings_for_resource["api"]["authentication_timeout"]).to eq("7331.minutes")

        expect {
          delete(
            api_server_settings_url(nil, server),
            :params => %i[api authentication_timeout].to_json # => hack because Rails will interpret these as query params in a DELETE
          )
        }.to change { server.settings_for_resource["api"]["authentication_timeout"] }.from("7331.minutes").to("30.seconds")

        expect(response).to have_http_status(:no_content)
      end

      it "does not allow an authenticated non-super-admin user to delete settings" do
        api_basic_authorize

        expect {
          delete(
            api_server_settings_url(nil, server),
            :params => %i[api authentication_timeout].to_json # => hack because Rails will interpret these as query params in a DELETE
          )
        }.not_to change { server.settings_for_resource["api"]["authentication_timeout"] }

        expect(response).to have_http_status(:forbidden)
      end

      it "does not allow an unauthenticated user to delete settings`" do
        expect {
          delete(
            api_server_settings_url(nil, server),
            :params => %i[api authentication_timeout].to_json # => hack because Rails will interpret these as query params in a DELETE
          )
        }.not_to change { server.settings_for_resource["api"]["authentication_timeout"] }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
