#
# Rest API Request Tests - Roles specs
#
# - Query all available features          /api/roles/:id/?expand=features       GET
# - Creating a role                       /api/roles                            POST
# - Creating a role via action            /api/roles                            action "create"
# - Creating multiple roles               /api/roles                            action "create"
# - Edit a role                           /api/roles/:id                        action "edit"
# - Edit multiple roles                   /api/roles                            action "edit"
# - Assign a single feature               /api/roles/:id/features               POST, action "assign"
# - Assign multiple features              /api/roles/:id/features               POST, action "assign"
# - Un-assign a single feature            /api/roles/:id/features               POST, action "unassign"
# - Un-assign multiple features           /api/roles/:id/features               POST, action "unassign"
# - Delete a role                         /api/roles/:id                        DELETE
# - Delete a role by action               /api/roles/:id                        action "delete"
# - Delete multiple roles                 /api/roles                            action "delete"
#
describe "Roles API" do
  let(:feature_identifiers) do
    %w(vm_explorer ems_infra_tag my_settings_time_profiles
       miq_request_view miq_report_run storage_manager_show_list rbac_role_show)
  end
  let(:expected_attributes) { %w(id name read_only settings) }
  let(:sample_role1) do
    {
      "name"     => "sample_role_1",
      "settings" => {"restrictions" => {"vms" => "user"}},
      "features" => [
        {:identifier => "vm_explorer"},
        {:identifier => "ems_infra_tag"},
        {:identifier => "my_settings_time_profiles"}
      ]
    }
  end
  let(:sample_role2) do
    {
      "name"     => "sample_role_2",
      "settings" => {"restrictions" => {"vms" => "user_or_group"}},
      "features" => [
        {:identifier => "miq_request_view"},
        {:identifier => "miq_report_run"},
        {:identifier => "storage_manager_show_list"}
      ]
    }
  end
  let(:features_list) do
    {
      "features"  => [
        {:identifier => "miq_request_view"},
        {:identifier => "miq_report_run"},
        {:identifier => "storage_manager_show_list"}
      ]
    }
  end

  before(:each) do
    @product_features = feature_identifiers.collect do |identifier|
      FactoryBot.create(:miq_product_feature, :identifier => identifier)
    end
  end

  def test_features_query(role, role_url, klass, attr = :id)
    api_basic_authorize action_identifier(:roles, :read, :resource_actions, :get)

    get role_url, :params => { :expand => "features" }
    expect(response).to have_http_status(:ok)

    expect(response.parsed_body).to have_key("name")
    expect(response.parsed_body["name"]).to eq(role.name)
    expect(response.parsed_body).to have_key("features")
    expect(response.parsed_body["features"].size).to eq(role.miq_product_features.count)

    expect_result_resources_to_include_data("features", attr.to_s => klass.pluck(attr))
  end

  describe "Features" do
    let(:role) { FactoryBot.create(:miq_user_role, :name => "Test Role", :miq_product_features => @product_features) }

    it "query available features" do
      test_features_query(role, api_role_url(nil, role), MiqProductFeature, :identifier)
    end

    it 'returns only the requested attributes' do
      api_basic_authorize action_identifier(:roles, :read, :collection_actions, :get)

      get api_roles_url, :params => { :expand => 'resources', :attributes => 'name' }

      expect(response).to have_http_status(:ok)
      response.parsed_body['resources'].each { |res| expect_hash_to_have_only_keys(res, %w(href id name)) }
    end

    it 'returns features by default when expanding the collection resources' do
      api_basic_authorize action_identifier(:roles, :read, :collection_actions, :get)

      get(api_roles_url, :params => { :expand => 'resources' })

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys('resources', %w(features))
    end

    it 'returns features by default for a role resource' do
      api_basic_authorize action_identifier(:roles, :read, :resource_actions, :get)

      get(api_role_url(nil, role))

      expected = {
        'features' => a_collection_including('href' => a_string_including(api_role_features_url(nil, role, nil)))
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Roles create" do
    it "rejects creation without appropriate role" do
      api_basic_authorize

      post(api_roles_url, :params => sample_role1)

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects role creation with id specified" do
      api_basic_authorize collection_action_identifier(:roles, :create)

      post(api_roles_url, :params => { "name" => "sample role", "id" => 100 })

      expect_bad_request(/id or href should not be specified/i)
    end

    it "supports single role creation" do
      api_basic_authorize collection_action_identifier(:roles, :create)

      post(api_roles_url, :params => sample_role1)

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)

      role_id = response.parsed_body["results"].first["id"]

      get(api_role_url(nil, role_id), :params => { :expand => "features" })

      role = MiqUserRole.find(role_id)

      sample_role1['features'].each do |feature|
        expect(role.allows?(feature)).to be_truthy
      end
    end

    it "supports single role creation via action" do
      api_basic_authorize collection_action_identifier(:roles, :create)

      post(api_roles_url, :params => gen_request(:create, sample_role1))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)

      role_id = response.parsed_body["results"].first["id"]
      role = MiqUserRole.find(role_id)
      sample_role1['features'].each do |feature|
        expect(role.allows?(feature)).to be_truthy
      end
    end

    it "supports multiple role creation" do
      api_basic_authorize collection_action_identifier(:roles, :create)

      post(api_roles_url, :params => gen_request(:create, [sample_role1, sample_role2]))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)

      results = response.parsed_body["results"]
      r1_id = results.first["id"]
      r2_id = results.second["id"]

      role1 = MiqUserRole.find(r1_id)
      role2 = MiqUserRole.find(r2_id)

      sample_role1['features'].each do |feature|
        expect(role1.allows?(feature)).to be_truthy
      end
      sample_role2['features'].each do |feature|
        expect(role2.allows?(feature)).to be_truthy
      end
    end
  end

  describe "Roles edit" do
    it "rejects role edits without appropriate role" do
      role = FactoryBot.create(:miq_user_role)
      api_basic_authorize
      post(api_roles_url, :params => gen_request(:edit, "name" => "role name", "href" => api_role_url(nil, role)))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects role edits for invalid resources" do
      api_basic_authorize collection_action_identifier(:roles, :edit)

      post(api_role_url(nil, 999_999), :params => gen_request(:edit, "name" => "updated role name"))

      expect(response).to have_http_status(:not_found)
    end

    it "supports single role edit" do
      api_basic_authorize collection_action_identifier(:roles, :edit)

      role = FactoryBot.create(:miq_user_role)

      post(
        api_role_url(nil, role),
        :params => gen_request(
          :edit,
          "name"     => "updated role",
          "settings" => {"restrictions" => {"vms" => "user_or_group"}}
        )
      )

      expect_single_resource_query("id"       => role.id.to_s,
                                   "name"     => "updated role",
                                   "settings" => {"restrictions" => {"vms" => "user_or_group"}})
      expect(role.reload.name).to eq("updated role")
      expect(role.settings[:restrictions][:vms]).to eq(:user_or_group)
    end

    it "supports multiple role edits" do
      api_basic_authorize collection_action_identifier(:roles, :edit)

      r1 = FactoryBot.create(:miq_user_role, :name => "role1")
      r2 = FactoryBot.create(:miq_user_role, :name => "role2")

      post(api_roles_url, :params => gen_request(:edit,
                                                 [{"href" => api_role_url(nil, r1), "name" => "updated role1"},
                                                  {"href" => api_role_url(nil, r2), "name" => "updated role2"}]))

      expect_results_to_match_hash("results",
                                   [{"id" => r1.id.to_s, "name" => "updated role1"},
                                    {"id" => r2.id.to_s, "name" => "updated role2"}])

      expect(r1.reload.name).to eq("updated role1")
      expect(r2.reload.name).to eq("updated role2")
    end
  end

  describe "Role Feature Assignments" do
    it "does not allow assigning features for an unauthorized user" do
      api_basic_authorize
      role = FactoryBot.create(:miq_user_role, :features => "miq_request_approval")

      new_feature = {:identifier => "miq_request_view"}
      url = api_role_features_url(nil, role)
      post(url, :params => gen_request(:assign, new_feature))

      expect(response).to have_http_status(:forbidden)

      # Confirm original feature
      role.reload
      expect(role.allows?(:identifier => 'miq_request_approval')).to be_truthy

      # Confirm new feature is not there
      expect(role.allows?(new_feature)).to be_falsey
    end

    it "supports assigning just a single product feature" do
      api_basic_authorize collection_action_identifier(:roles, :edit)
      role = FactoryBot.create(:miq_user_role, :features => "miq_request_approval")

      new_feature = {:identifier => "miq_request_view"}
      url = api_role_features_url(nil, role)
      post(url, :params => gen_request(:assign, new_feature))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", %w(id name read_only))

      # Confirm original feature
      role.reload
      expect(role.allows?(:identifier => 'miq_request_approval')).to be_truthy

      # Confirm new feature
      expect(role.allows?(new_feature)).to be_truthy
    end

    it "supports assigning multiple product features" do
      api_basic_authorize collection_action_identifier(:roles, :edit)
      role = FactoryBot.create(:miq_user_role, :features => "miq_request_approval")

      post(api_role_features_url(nil, role), :params => gen_request(:assign, features_list))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", %w(id name read_only))

      # Refresh the role object
      role = MiqUserRole.find(role.id)

      # Confirm original feature
      expect(role.allows?(:identifier => 'miq_request_approval')).to be_truthy

      # Confirm new features
      features_list['features'].each do |feature|
        expect(role.allows?(feature)).to be_truthy
      end
    end

    it "supports un-assigning just a single product feature" do
      api_basic_authorize collection_action_identifier(:roles, :edit)
      role = FactoryBot.create(:miq_user_role, :miq_product_features => @product_features)

      removed_feature = {:identifier => "ems_infra_tag"}
      url = api_role_features_url(nil, role)
      post(url, :params => gen_request(:unassign, removed_feature))

      expect(response).to have_http_status(:ok)
      # Confirm that we've only removed ems_infra_tag
      expect_result_resources_to_include_keys("results", %w(id name read_only))

      # Refresh the role object
      role = MiqUserRole.find(role.id)

      @product_features.each do |feature|
        unless feature[:identifier].eql?('ems_infra_tag')
          expect(role.allows?(:identifier => feature.identifier)).to be_truthy
        end
        if feature[:identifier].eql?('ems_infra_tag')
          expect(role.allows?(:identifier => feature.identifier)).to be_falsey
        end
      end
    end

    it "supports un-assigning multiple product features" do
      api_basic_authorize collection_action_identifier(:roles, :edit)
      role = FactoryBot.create(:miq_user_role, :miq_product_features => @product_features)

      url = api_role_features_url(nil, role)
      post(url, :params => gen_request(:unassign, features_list))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", %w(id name read_only))

      # Refresh the role object
      role = MiqUserRole.find(role.id)

      # Confirm requested features removed first, and others remain
      @product_features.each do |feature|
        removed = features_list['features'].find do |removed_feature|
          removed_feature[:identifier] == feature[:identifier]
        end

        if removed
          expect(role.allows?(:identifier => feature.identifier)).to be_falsey
        else
          expect(role.allows?(:identifier => feature.identifier)).to be_truthy
        end
      end
    end
  end

  describe "Roles delete" do
    it "rejects role deletion, by post action, without appropriate role" do
      api_basic_authorize

      post(api_roles_url, :params => gen_request(:delete, "name" => "role name", "href" => api_role_url(nil, 100)))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects role deletion without appropriate role" do
      api_basic_authorize

      delete(api_role_url(nil, 100))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects role deletes for invalid roles" do
      api_basic_authorize collection_action_identifier(:roles, :delete)

      delete(api_role_url(nil, 999_999))

      expect(response).to have_http_status(:not_found)
    end

    it "supports single role delete" do
      api_basic_authorize collection_action_identifier(:roles, :delete)

      role = FactoryBot.create(:miq_user_role, :name => "role1")

      delete(api_role_url(nil, role))

      expect(response).to have_http_status(:no_content)
      expect(MiqUserRole.exists?(role.id)).to be_falsey
    end

    it "supports single role delete action" do
      api_basic_authorize collection_action_identifier(:roles, :delete)

      role = FactoryBot.create(:miq_user_role, :name => "role1")

      post(api_role_url(nil, role), :params => gen_request(:delete))

      expect(response).to have_http_status(:ok)
      expect(MiqUserRole.exists?(role.id)).to be_falsey
    end

    it "supports multiple role deletes" do
      api_basic_authorize collection_action_identifier(:roles, :delete)

      r1 = FactoryBot.create(:miq_user_role, :name => "role name 1")
      r2 = FactoryBot.create(:miq_user_role, :name => "role name 2")

      post(api_roles_url, :params => gen_request(:delete,
                                                 [{"href" => api_role_url(nil, r1)},
                                                  {"href" => api_role_url(nil, r2)}]))

      expect(response).to have_http_status(:ok)
      expect(MiqUserRole.exists?(r1.id)).to be_falsey
      expect(MiqUserRole.exists?(r2.id)).to be_falsey
    end
  end
end
