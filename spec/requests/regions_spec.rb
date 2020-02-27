#
# REST API Request Tests - Regions
#
# Regions primary collections:
#   /api/regions
#
# Tests for:
# GET /api/regions/:id
#

RSpec.describe "Regions API", :regions do
  context "authorization", :authorization do
    it "forbids access to regions without an appropriate role" do
      api_basic_authorize

      get(api_regions_url)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids access to a region resource without an appropriate role" do
      api_basic_authorize

      region = FactoryBot.create(:miq_region, :region => "2")

      get(api_region_url(nil, region))

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "get", :get do
    it "allows GETs of a region" do
      api_basic_authorize action_identifier(:regions, :read, :resource_actions, :get)

      region = FactoryBot.create(:miq_region, :region => "2")

      get(api_region_url(nil, region))

      expect_single_resource_query(
        "href" => api_region_url(nil, region),
        "id"   => region.id.to_s
      )
    end
  end

  context "edit", :edit do
    it "can update a region with POST" do
      api_basic_authorize action_identifier(:regions, :edit)

      region = FactoryBot.create(:miq_region, :description => "Current Region description")

      post api_region_url(nil, region), :params => gen_request(:edit, :description => "New Region description")

      expect(response).to have_http_status(:ok)
      region.reload
      expect(region.description).to eq("New Region description")
    end

    it "will fail if you try to edit forbidden fields" do
      api_basic_authorize action_identifier(:regions, :edit)

      region = FactoryBot.create(:miq_region, :description => "Current Region description")

      post api_region_url(nil, region), :params => gen_request(:edit, :created_at => Time.now.utc)
      expect_bad_request("Attribute(s) 'created_at' should not be specified for updating a region resource")

      post api_region_url(nil, region), :params => gen_request(:edit, :updated_at => Time.now.utc)
      expect_bad_request("Attribute(s) 'updated_at' should not be specified for updating a region resource")
    end

    it "can update multiple regions with POST" do
      api_basic_authorize action_identifier(:regions, :edit)

      region1 = FactoryBot.create(:miq_region, :description => "Test Region 1")
      region2 = FactoryBot.create(:miq_region, :description => "Test Region 2")

      options = [
        {"href" => api_region_url(nil, region1), "description" => "Updated Test Region 1"},
        {"href" => api_region_url(nil, region2), "description" => "Updated Test Region 2"}
      ]

      post api_regions_url, :params => gen_request(:edit, options)

      expect(response).to have_http_status(:ok)

      expect_results_to_match_hash(
        "results",
        [
          {"id" => region1.id.to_s, "description" => "Updated Test Region 1"},
          {"id" => region2.id.to_s, "description" => "Updated Test Region 2"}
        ]
      )

      expect(region1.reload.description).to eq("Updated Test Region 1")
      expect(region2.reload.description).to eq("Updated Test Region 2")
    end

    it "will fail to update multiple regions if any forbidden fields are edited" do
      api_basic_authorize action_identifier(:regions, :edit)

      region1 = FactoryBot.create(:miq_region, :description => "Test Region 1")
      region2 = FactoryBot.create(:miq_region, :description => "Test Region 2")

      options = [
        {"href" => api_region_url(nil, region1), "description" => "New description"},
        {"href" => api_region_url(nil, region2), "created_at" => Time.now.utc}
      ]

      post api_regions_url, :params => gen_request(:edit, options)

      expect_bad_request("Attribute(s) 'created_at' should not be specified for updating a region resource")
    end

    it "forbids edit of a region without an appropriate role" do
      api_basic_authorize

      region = FactoryBot.create(:miq_region, :description => "Current Region description")

      post api_region_url(nil, region), :params => gen_request(:edit, :description => "New Region description")

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "delete", :delete do
    it "forbids deletion of a region" do
      region = FactoryBot.create(:miq_region, :description => "Current Region description")
      delete(api_region_url(nil, region))
      expect(response).to have_http_status(:not_found)
    end
  end

  context "Settings", :settings do
    let(:region_number) { ApplicationRecord.my_region_number + 1 }
    let(:id) { ApplicationRecord.id_in_region(1, region_number) }
    let(:region) { FactoryBot.create(:miq_region, :id => id, :region => region_number) }

    context "/api/regions/:id?expand=settings" do
      it "expands the settings subcollection" do
        api_basic_authorize(action_identifier(:regions, :read, :resource_actions, :get), :ops_settings)
        allow(Vmdb::Settings).to receive(:for_resource).and_return('authentications' => { 'bind_pwd' => 'bad_val'})
        allow(User).to receive(:current_user).and_return(@user)
        allow(@user).to receive(:super_admin_user?).and_return(true)

        get(api_region_url(nil, region), :params => {:expand => 'settings'})

        expect(response.parsed_body).to include('settings' => {'authentications' => {}})
        expect(response).to have_http_status(:ok)
      end

      it "does not expand settings without an appropriate role" do
        api_basic_authorize(action_identifier(:regions, :read, :resource_actions, :get))

        get(api_region_url(nil, region), :params => {:expand => 'settings'})

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "/api/regions/:id/settings" do
      let(:zone) { FactoryBot.create(:zone, :id => id) }
      let!(:server) { EvmSpecHelper.remote_miq_server(:id => id, :zone => zone) }
      let(:original_timeout) { region.settings_for_resource[:api][:authentication_timeout] }
      let(:super_admin) { FactoryBot.create(:user, :role => 'super_administrator', :userid => 'alice', :password => 'alicepassword') }

      it "shows the settings to an authenticated user with the proper role" do
        api_basic_authorize(:ops_settings)

        get(api_region_settings_url(nil, region))

        expect(response).to have_http_status(:ok)
      end

      it "does not allow an authenticated user who doesn't have the proper role to view the settings" do
        api_basic_authorize

        get(api_region_settings_url(nil, region))

        expect(response).to have_http_status(:forbidden)
      end

      it "does not allow an unauthenticated user to view the settings" do
        get(api_region_settings_url(nil, region))

        expect(response).to have_http_status(:unauthorized)
      end

      it "permits updates to settings for an authenticated super-admin user" do
        api_basic_authorize(:user => super_admin.userid, :password => super_admin.password)

        expect {
          patch(api_region_settings_url(nil, region), :params => {:api => {:authentication_timeout => "1337.minutes"}})
        }.to change { region.settings_for_resource[:api][:authentication_timeout] }.from(original_timeout).to("1337.minutes")

        expect(response.parsed_body).to include("api" => a_hash_including("authentication_timeout" => "1337.minutes"))
        expect(response).to have_http_status(:ok)
      end

      it "does not allow an authenticated non-super-admin user to update settings" do
        api_basic_authorize

        expect {
          patch(api_region_settings_url(nil, region), :params => {:api => {:authentication_timeout => "10.minutes"}})
        }.not_to change { region.settings_for_resource[:api][:authentication_timeout] }

        expect(response).to have_http_status(:forbidden)
      end

      it "does not allow an unauthenticated user to update the settings" do
        expect {
          patch(api_region_settings_url(nil, region), :params => {:api => {:authentication_timeout => "10.minutes"}})
        }.not_to change { region.settings_for_resource[:api][:authentication_timeout] }

        expect(response).to have_http_status(:unauthorized)
      end

      context "with an existing settings change" do
        before do
          region.add_settings_for_resource("api" => {"authentication_timeout" => "7331.minutes"})
        end

        it "allows an authenticated super-admin user to delete settings" do
          api_basic_authorize(:user => super_admin.userid, :password => super_admin.password)
          expect(region.settings_for_resource["api"]["authentication_timeout"]).to eq("7331.minutes")

          expect {
            delete(
              api_region_settings_url(nil, region),
              :params => %i[api authentication_timeout].to_json # => hack because Rails will interpret these as query params in a DELETE
            )
          }.to change { region.settings_for_resource["api"]["authentication_timeout"] }.from("7331.minutes").to("30.seconds")

          expect(response).to have_http_status(:no_content)
        end

        it "does not allow an authenticated non-super-admin user to delete settings" do
          api_basic_authorize

          expect {
            delete(
              api_region_settings_url(nil, region),
              :params => %i[api authentication_timeout].to_json # => hack because Rails will interpret these as query params in a DELETE
            )
          }.not_to change { region.settings_for_resource["api"]["authentication_timeout"] }

          expect(response).to have_http_status(:forbidden)
        end

        it "does not allow an unauthenticated user to delete settings`" do
          expect {
            delete(
              api_region_settings_url(nil, region),
              :params => %i[api authentication_timeout].to_json # => hack because Rails will interpret these as query params in a DELETE
            )
          }.not_to change { region.settings_for_resource["api"]["authentication_timeout"] }

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
