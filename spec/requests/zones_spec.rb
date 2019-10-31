RSpec.describe "Zones" do
  let(:zone) { FactoryBot.create(:zone) }

  context "authorization", :authorization do
    it "forbids access to zones without an appropriate role" do
      expect_forbidden_request { get(api_zones_url) }
    end

    it "forbids access to a zone resource without an appropriate role" do
      expect_forbidden_request { get(api_zone_url(nil, zone)) }
    end
  end

  context "get", :get do
    it "allows GETs of a zone" do
      api_basic_authorize action_identifier(:zones, :read, :resource_actions, :get)

      get(api_zone_url(nil, zone))

      expect_single_resource_query(
        "href" => api_zone_url(nil, zone),
        "id"   => zone.id.to_s
      )
    end
  end

  context "edit", :edit do
    it "will fail if you try to edit invalid fields" do
      api_basic_authorize action_identifier(:zones, :edit)

      zone = FactoryBot.create(:zone, :description => "Current Zone description")

      post api_zone_url(nil, zone), :params => gen_request(:edit, :created_on => Time.now.utc)
      expect_bad_request("Attribute(s) 'created_on' should not be specified for updating a zone resource")

      post api_zone_url(nil, zone), :params => gen_request(:edit, :updated_on => Time.now.utc)
      expect_bad_request("Attribute(s) 'updated_on' should not be specified for updating a zone resource")
    end

    it "can update multiple zones with POST" do
      api_basic_authorize action_identifier(:zones, :edit)

      zone1 = FactoryBot.create(:zone, :description => "Test Zone 1")
      zone2 = FactoryBot.create(:zone, :description => "Test Zone 2")

      options = [
        {"href" => api_zone_url(nil, zone1), "description" => "Updated Test Zone 1"},
        {"href" => api_zone_url(nil, zone2), "description" => "Updated Test Zone 2"}
      ]

      post api_zones_url, :params => gen_request(:edit, options)

      expect(response).to have_http_status(:ok)

      expect_results_to_match_hash(
        "results",
        [
          {"id" => zone1.id.to_s, "description" => "Updated Test Zone 1"},
          {"id" => zone2.id.to_s, "description" => "Updated Test Zone 2"}
        ]
      )

      expect(zone1.reload.description).to eq("Updated Test Zone 1")
      expect(zone2.reload.description).to eq("Updated Test Zone 2")
    end

    it "will fail to update multiple zones if any invalid fields are edited" do
      api_basic_authorize action_identifier(:zones, :edit)

      zone1 = FactoryBot.create(:zone, :description => "Test Zone 1")
      zone2 = FactoryBot.create(:zone, :description => "Test Zone 2")

      options = [
        {"href" => api_zone_url(nil, zone1), "description" => "New description"},
        {"href" => api_zone_url(nil, zone2), "created_on" => Time.now.utc}
      ]

      post api_zones_url, :params => gen_request(:edit, options)

      expect_bad_request("Attribute(s) 'created_on' should not be specified for updating a zone resource")
    end

    it "forbids edit of a zone without an appropriate role" do
      expect_forbidden_request do
        zone = FactoryBot.create(:zone, :description => "Current Zone description")
        post(api_zone_url(nil, zone), :params => gen_request(:edit, :description => "New Zone description"))
      end
    end
  end

  context "delete", :delete do
    it "can delete a zone with POST" do
      api_basic_authorize action_identifier(:zones, :delete)
      zone = FactoryBot.create(:zone)

      expect { post api_zone_url(nil, zone), :params => gen_request(:delete) }.to change(Zone, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end

    it "cannot delete a default zone with POST" do
      api_basic_authorize action_identifier(:zones, :delete)
      zone = FactoryBot.create(:zone, :name => 'default')

      expect { post api_zone_url(nil, zone), :params => gen_request(:delete) }.to change(Zone, :count).by(0)
      expect_single_action_result(:success => false, :message => 'cannot delete default zone')
    end

    it "can delete a zone with DELETE" do
      api_basic_authorize action_identifier(:zones, :delete)
      zone = FactoryBot.create(:zone)

      expect { delete api_zone_url(nil, zone) }.to change(Zone, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "cannot delete a default zone with DELETE" do
      api_basic_authorize action_identifier(:zones, :delete)
      zone = FactoryBot.create(:zone, :name => 'default')

      expect { delete api_zone_url(nil, zone) }.to change(Zone, :count).by(0)
    end

    it "can delete multiple zones with POST" do
      api_basic_authorize action_identifier(:zones, :delete)
      zones = FactoryBot.create_list(:zone, 2)

      options = [
        {"href" => api_zone_url(nil, zones.first)},
        {"href" => api_zone_url(nil, zones.last)}
      ]

      expect { post api_zones_url, :params => gen_request(:delete, options) }.to change(Zone, :count).by(-2)
      expect(response).to have_http_status(:ok)
    end

    it "forbids deletion of a zone without an appropriate role" do
      expect_forbidden_request do
        zone = FactoryBot.create(:zone, :description => "Current Region description")
        delete api_zone_url(nil, zone)
      end
    end
  end

  describe "/api/zones/:id?expand=settings", :settings do
    it "expands the settings subcollection" do
      api_basic_authorize(action_identifier(:zones, :read, :resource_actions, :get), :ops_settings)

      get(api_zone_url(nil, zone), :params => {:expand => 'settings'})

      expect(response.parsed_body).to include('settings' => a_kind_of(Hash))
      expect(response).to have_http_status(:ok)
    end

    it "does not expand settings without an appropriate role" do
      api_basic_authorize(action_identifier(:zones, :read, :resource_actions, :get))

      get(api_zone_url(nil, zone), :params => {:expand => 'settings'})

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "/api/zones/:id/settings" do
    let(:original_timeout) { zone.settings_for_resource[:api][:authentication_timeout] }
    let(:super_admin) { FactoryBot.create(:user, :role => 'super_administrator', :userid => 'alice', :password => 'alicepassword') }

    it "shows the settings to an authenticated user with the proper role" do
      api_basic_authorize(:ops_settings)

      get(api_zone_settings_url(nil, zone))

      expect(response).to have_http_status(:ok)
    end

    it "does not allow an authenticated user who doesn't have the proper role to view the settings" do
      expect_forbidden_request { get(api_zone_settings_url(nil, zone)) }
    end

    it "does not allow an unauthenticated user to view the settings" do
      get(api_zone_settings_url(nil, zone))

      expect(response).to have_http_status(:unauthorized)
    end

    it "permits updates to settings for an authenticated super-admin user" do
      api_basic_authorize(:user => super_admin.userid, :password => super_admin.password)

      expect {
        patch(api_zone_settings_url(nil, zone), :params => {:api => {:authentication_timeout => "1337.minutes"}})
      }.to change { zone.settings_for_resource[:api][:authentication_timeout] }.from(original_timeout).to("1337.minutes")

      expect(response.parsed_body).to include("api" => a_hash_including("authentication_timeout" => "1337.minutes"))
      expect(response).to have_http_status(:ok)
    end

    it "does not allow an authenticated non-super-admin user to update settings" do
      api_basic_authorize

      expect {
        patch(api_zone_settings_url(nil, zone), :params => {:api => {:authentication_timeout => "10.minutes"}})
      }.not_to change { zone.settings_for_resource[:api][:authentication_timeout] }

      expect(response).to have_http_status(:forbidden)
    end

    it "does not allow an unauthenticated user to update the settings" do
      expect {
        patch(api_zone_settings_url(nil, zone), :params => {:api => {:authentication_timeout => "10.minutes"}})
      }.not_to change { zone.settings_for_resource[:api][:authentication_timeout] }

      expect(response).to have_http_status(:unauthorized)
    end

    context "with an existing settings change" do
      before do
        zone.add_settings_for_resource("api" => {"authentication_timeout" => "7331.minutes"})
      end

      it "allows an authenticated super-admin user to delete settings" do
        api_basic_authorize(:user => super_admin.userid, :password => super_admin.password)
        expect(zone.settings_for_resource["api"]["authentication_timeout"]).to eq("7331.minutes")

        expect {
          delete(
            api_zone_settings_url(nil, zone),
            :params => %i[api authentication_timeout].to_json # => hack because Rails will interpret these as query params in a DELETE
          )
        }.to change { zone.settings_for_resource["api"]["authentication_timeout"] }.from("7331.minutes").to("30.seconds")

        expect(response).to have_http_status(:no_content)
      end

      it "does not allow an authenticated non-super-admin user to delete settings" do
        api_basic_authorize

        expect {
          delete(
            api_zone_settings_url(nil, zone),
            :params => %i[api authentication_timeout].to_json # => hack because Rails will interpret these as query params in a DELETE
          )
        }.not_to change { zone.settings_for_resource["api"]["authentication_timeout"] }

        expect(response).to have_http_status(:forbidden)
      end

      it "does not allow an unauthenticated user to delete settings`" do
        expect {
          delete(
            api_zone_settings_url(nil, zone),
            :params => %i[api authentication_timeout].to_json # => hack because Rails will interpret these as query params in a DELETE
          )
        }.not_to change { zone.settings_for_resource["api"]["authentication_timeout"] }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
