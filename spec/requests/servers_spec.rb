RSpec.describe "Servers" do
  describe "/api/servers/:id/settings" do
    let(:server) { FactoryGirl.create(:miq_server, :zone => FactoryGirl.create(:zone, :name => "default")) }
    let(:original_timeout) { server.settings_for_resource[:api][:authentication_timeout] }
    let(:super_admin) { FactoryGirl.create(:user, :role => 'super_administrator', :userid => 'alice', :password => 'alicepassword') }


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
