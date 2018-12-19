RSpec.describe "Flavors API" do
  describe "as a subcollection of providers" do
    describe "GET /api/providers/:c_id/flavors" do
      it "can list the flavors of a provider" do
        api_basic_authorize(action_identifier(:flavors, :read, :subcollection_actions, :get))
        ems = FactoryBot.create(:ems_cloud)
        flavor = FactoryBot.create(:flavor, :ext_management_system => ems)

        get(api_provider_flavors_url(nil, ems))

        expected = {
          "count"     => 1,
          "name"      => "flavors",
          "resources" => [
            {"href" => api_provider_flavor_url(nil, ems, flavor)}
          ]
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not list flavors unless authorized" do
        api_basic_authorize
        ems = FactoryBot.create(:ems_cloud)
        FactoryBot.create(:flavor, :ext_management_system => ems)

        get(api_provider_flavors_url(nil, ems))

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns an empty array for collections that do not have flavors' do
        ems_infra = FactoryBot.create(:ems_infra)
        api_basic_authorize(subcollection_action_identifier(:providers, :flavors, :read, :get))

        get(api_provider_flavors_url(nil, ems_infra))

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('resources' => [])
      end
    end

    describe "GET /api/providers/:c_id/flavors/:id" do
      it "can show a provider's flavor" do
        api_basic_authorize(action_identifier(:flavors, :read, :subresource_actions, :get))
        ems = FactoryBot.create(:ems_cloud)
        flavor = FactoryBot.create(:flavor, :ext_management_system => ems)

        get(api_provider_flavor_url(nil, ems, flavor))

        expected = {
          "href" => api_provider_flavor_url(nil, ems, flavor),
          "id"   => flavor.id.to_s
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not show a flavor unless authorized" do
        api_basic_authorize
        ems = FactoryBot.create(:ems_cloud)
        flavor = FactoryBot.create(:flavor, :ext_management_system => ems)

        get(api_provider_flavor_url(nil, ems, flavor))

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /api/providers/:c_id/flavors" do
      it "can queue the creation of a flavors" do
        api_basic_authorize(action_identifier(:flavors, :create, :subcollection_actions))
        ems = FactoryBot.create(:ems_cloud)

        post(api_provider_flavors_url(nil, ems), :params => { :name => "test-flavor" })

        expected = {
          "results" => [
            a_hash_including(
              "success"   => true,
              "message"   => "Creating Flavor",
              "task_id"   => anything,
              "task_href" => a_string_matching(api_tasks_url)
            )
          ]
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not create a flavor unless authorized" do
        api_basic_authorize
        ems = FactoryBot.create(:ems_cloud)

        post(api_provider_flavors_url(nil, ems), :params => { :name => "test-flavor" })

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /api/providers/:c_id/flavors/:s_id with delete action" do
      it "can queue a flavor for deletion" do
        api_basic_authorize(action_identifier(:flavors, :delete, :subresource_actions))

        ems = FactoryBot.create(:ems_cloud)
        flavor = FactoryBot.create(:flavor, :ext_management_system => ems)

        post(api_provider_flavor_url(nil, ems, flavor), :params => { :action => "delete" })

        expected = {
          "message"   => "Deleting Flavor id:#{flavor.id} name: '#{flavor.name}'",
          "success"   => true,
          "task_href" => a_string_matching(api_tasks_url),
          "task_id"   => anything
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not delete a flavor unless authorized" do
        api_basic_authorize
        ems = FactoryBot.create(:ems_cloud)
        flavor = FactoryBot.create(:flavor, :ext_management_system => ems)

        post(api_provider_flavor_url(nil, ems, flavor), :params => { :action => "delete" })

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /api/providers/:c_id/flavors/ with delete action" do
      it "can delete multiple flavors" do
        ems = FactoryBot.create(:ems_cloud)
        flavor1, flavor2 = FactoryBot.create_list(:flavor, 2)

        api_basic_authorize(action_identifier(:flavors, :delete, :subresource_actions))

        post(api_provider_flavors_url(nil, ems), :params => { :action => "delete", :resources => [{:id => flavor1.id},
                                                                                                  {:id => flavor2.id}] })

        expect(response).to have_http_status(:ok)
      end

      it "forbids multiple flavor deletion without an appropriate role" do
        ems = FactoryBot.create(:ems_cloud)
        flavor1, flavor2 = FactoryBot.create_list(:flavor, 2)

        api_basic_authorize

        post(api_provider_flavors_url(nil, ems), :params => { :action => "delete", :resources => [{:id => flavor1.id},
                                                                                                  {:id => flavor2.id}] })

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "DELETE /api/providers/:c_id/flavors/:s_id" do
      it "can delete a flavor" do
        ems = FactoryBot.create(:ems_cloud)
        flavor = FactoryBot.create(:flavor, :ext_management_system => ems)

        api_basic_authorize(action_identifier(:flavors, :delete, :subresource_actions, :delete))

        delete(api_provider_flavor_url(nil, ems, flavor))

        expect(response).to have_http_status(:no_content)
      end

      it "will not delete a flavor unless authorized" do
        ems = FactoryBot.create(:ems_cloud)
        flavor = FactoryBot.create(:flavor, :ext_management_system => ems)

        api_basic_authorize

        delete(api_provider_flavor_url(nil, ems, flavor))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
