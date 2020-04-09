#
# REST API Request Tests - Policies and Policy Profiles
#
# Policy and Policy Profiles primary collections:
#   /api/policies
#   /api/policy_profiles
#
# Policy subcollection:
#   /api/vms/:id/policies
#   /api/providers/:id/policies
#   /api/hosts/:id/policies
#   /api/resource_pools/:id/policies
#   /api/clusters/:id/policies
#   /api/templates/:id/policies
#   /api/policy_profiles/:id/policies
#
# Policy Profiles subcollection:
#   /api/vms/:id/policy_profiles
#   /api/providers/:id/policy_profiles
#   /api/hosts/:id/policy_profiles
#   /api/resource_pools/:id/policy_profiles
#   /api/clusters/:id/policy_profiles
#   /api/templates/:id/policy_profiles
#
describe "Policies API" do
  let(:zone)        { FactoryBot.create(:zone, :name => "api_zone") }
  let(:ems)         { FactoryBot.create(:ems_vmware, :zone => zone) }
  let(:host)        { FactoryBot.create(:host) }

  let(:p1)          { FactoryBot.create(:miq_policy, :description => "Policy 1") }
  let(:p2)          { FactoryBot.create(:miq_policy, :description => "Policy 2") }
  let(:p3)          { FactoryBot.create(:miq_policy, :description => "Policy 3") }

  let(:ps1)         { FactoryBot.create(:miq_policy_set, :description => "Policy Set 1") }
  let(:ps2)         { FactoryBot.create(:miq_policy_set, :description => "Policy Set 2") }

  let(:p_guids)     { [p1.guid, p2.guid] }
  let(:p_all_guids) { [p1.guid, p2.guid, p3.guid] }

  before do
    # Creating:  policy_set_1 = [policy_1, policy_2]  and  policy_set_2 = [policy_3]
    ps1.add_member(p1)
    ps1.add_member(p2)

    ps2.add_member(p3)
  end

  def test_no_policy_query(api_object_policies_url)
    api_basic_authorize

    get api_object_policies_url

    expect_empty_query_result(:policies)
  end

  def test_no_policy_profile_query(api_object_policy_profiles_url)
    api_basic_authorize

    get api_object_policy_profiles_url

    expect_empty_query_result(:policy_profiles)
  end

  def test_single_policy_query(object, api_object_policies_url)
    api_basic_authorize

    object.add_policy(p1)
    object.add_policy(ps2)

    get api_object_policies_url, :params => { :expand => "resources" }

    expect_query_result(:policies, 1)
    expect_result_resources_to_match_hash([{"name" => p1.name, "description" => p1.description, "guid" => p1.guid}])
  end

  def test_multiple_policy_query(object, api_object_policies_url)
    api_basic_authorize

    object.add_policy(p1)
    object.add_policy(p2)
    object.add_policy(ps2)

    get api_object_policies_url, :params => { :expand => "resources" }

    expect_query_result(:policies, 2)
    expect_result_resources_to_include_data("resources", "guid" => p_guids)
  end

  def test_policy_profile_query(object, api_object_policy_profiles_url)
    api_basic_authorize

    object.add_policy(p1)
    object.add_policy(ps2)

    get api_object_policy_profiles_url, :params => { :expand => "resources" }

    expect_query_result(:policy_profiles, 1)
    expect_result_resources_to_include_data("resources", "guid" => Array.wrap(ps2.guid))
  end

  def test_policy_profile_policies_query(object, api_object_policy_profiles_url)
    api_basic_authorize

    object.add_policy(ps1)
    object.add_policy(ps2)

    get api_object_policy_profiles_url, :params => {:expand => "resources", :attributes => "miq_policies"}

    expected = {
      "name"      => "policy_profiles",
      "count"     => 2,
      "resources" => a_collection_containing_exactly(
        a_hash_including(
          "guid"         => ps1.guid,
          "miq_policies" => a_collection_containing_exactly(
            a_hash_including("guid" => p1.guid),
            a_hash_including("guid" => p2.guid)
          )
        ),
        a_hash_including(
          "guid"         => ps2.guid,
          "miq_policies" => a_collection_containing_exactly(
            a_hash_including("guid" => p3.guid)
          )
        )
      )
    }
    expect(response.parsed_body).to include(expected)
  end

  context "Policy collection" do
    it "query invalid policy" do
      api_basic_authorize action_identifier(:policies, :read, :resource_actions, :get)

      get api_policy_url(nil, 999_999)

      expect(response).to have_http_status(:not_found)
    end

    it "query policies" do
      api_basic_authorize collection_action_identifier(:policies, :read, :get)

      get api_policies_url

      expect_query_result(:policies, 3, 3)
      expect_result_resources_to_include_hrefs(
        "resources",
        [api_policy_url(nil, p1), api_policy_url(nil, p2), api_policy_url(nil, p3)]
      )
    end

    it "query policies in expanded form" do
      api_basic_authorize collection_action_identifier(:policies, :read, :get)

      get api_policies_url, :params => { :expand => "resources" }

      expect_query_result(:policies, 3, 3)
      expect_result_resources_to_include_data("resources", "guid" => p_all_guids)
    end
  end

  context "Policy Profile collection" do
    let(:policy_profile)     { ps1 }
    let(:new_policy_profile) do
      {:name => "New Policy Profile", :description => "My Profile", :mode => "compliance"}
    end


    it "query invalid policy profile" do
      api_basic_authorize action_identifier(:policy_profiles, :read, :resource_actions, :get)

      get api_policy_profile_url(nil, 999_999)

      expect(response).to have_http_status(:not_found)
    end

    it "query Policy Profiles" do
      api_basic_authorize collection_action_identifier(:policy_profiles, :read, :get)

      get api_policy_profiles_url

      expect_query_result(:policy_profiles, 2, 2)
      expect_result_resources_to_include_hrefs(
        "resources",
        [api_policy_profile_url(nil, ps1), api_policy_profile_url(nil, ps2)]
      )
    end

    it "query individual Policy Profile" do
      api_basic_authorize action_identifier(:policy_profiles, :read, :resource_actions, :get)

      get api_policy_profile_url(nil, policy_profile)

      expect_single_resource_query(
        "name" => policy_profile.name, "description" => policy_profile.description, "guid" => policy_profile.guid
      )
    end

    it "query Policy Profile policies subcollection" do
      api_basic_authorize

      get api_policy_profile_policies_url(nil, policy_profile), :params => { :expand => "resources" }

      expect_query_result(:policies, p_guids.count)
      expect_result_resources_to_include_data("resources", "guid" => p_guids)
    end

    it "query Policy Profile with expanded policies subcollection" do
      api_basic_authorize action_identifier(:policy_profiles, :read, :resource_actions, :get)

      get api_policy_profile_url(nil, policy_profile), :params => { :expand => "policies" }

      expect_single_resource_query(
        "name" => policy_profile.name, "description" => policy_profile.description, "guid" => policy_profile.guid
      )
      expect_result_resources_to_include_data("policies", "guid" => p_guids)
    end

    it "creates policy_profiles" do
      api_basic_authorize collection_action_identifier(:policy_profiles, :create)
      post(api_policy_profiles_url, :params => new_policy_profile.merge(:action => "create"))

      expect(response.parsed_body["results"].first["name"]).to eq("New Policy Profile")
      expect(response.parsed_body["results"].first["mode"]).to eq("compliance")

      policy_profile = MiqPolicySet.find(response.parsed_body["results"].first["id"])
      expect(policy_profile).to be_truthy
      expect(response).to have_http_status(:ok)
    end

    it "edits a policy_profile" do
      policy_profile = FactoryBot.create(:miq_policy_set, :description => "Policy Set")

      api_basic_authorize resource_action_identifier(:policy_profiles, :edit)
      post(api_policy_profile_url(nil, policy_profile), :params => gen_request(:edit, :name => "New Name"))

      expect(response).to have_http_status(:ok)

      policy_profile.reload
      expect(policy_profile.name).to eq("New Name")
    end

    it "editing a non-existing policy_profile" do
      api_basic_authorize resource_action_identifier(:policy_profiles, :edit)
      post(api_policy_profile_url(nil, 99_999), :params => gen_request(:edit, :name => "New Name"))

      expect(response).to have_http_status(:not_found)
    end

    it "does not allow editing a read_only policy_profile" do
      policy_profile = FactoryBot.create(:miq_policy_set, :description => "Policy Set", :read_only => true)

      api_basic_authorize resource_action_identifier(:policy_profiles, :edit)
      post(api_policy_profile_url(nil, policy_profile), :params => gen_request(:edit, :name => "New Name"))

      expect(response).to have_http_status(:forbidden)
    end

    it "POST deletes a policy_profile" do
      policy_profile = FactoryBot.create(:miq_policy_set, :description => "Policy Set")

      api_basic_authorize resource_action_identifier(:policy_profiles, :delete)
      post(api_policy_profile_url(nil, policy_profile), :params => gen_request(:delete))

      expect(response).to have_http_status(:ok)

      expect(MiqPolicySet.exists?(policy_profile.id)).to be_falsey
    end

    it "DELETE deletes a policy_profile" do
      policy_profile = FactoryBot.create(:miq_policy_set, :description => "Policy Set")
      api_basic_authorize resource_action_identifier(:policy_profiles, :delete, :delete)
      delete(api_policy_profile_url(nil, policy_profile))

      expect(response).to have_http_status(:no_content)

      expect(MiqPolicySet.exists?(policy_profile.id)).to be_falsey
    end

    it "DELETE does not allow deleting a read_only policy_profile" do
      policy_profile = FactoryBot.create(:miq_policy_set, :description => "Policy Set", :read_only => true)
      api_basic_authorize resource_action_identifier(:policy_profiles, :delete, :delete)
      delete(api_policy_profile_url(nil, policy_profile))

      expect(response).to have_http_status(:forbidden)

      expect(MiqPolicySet.exists?(policy_profile.id)).to be_truthy
    end
  end

  context "Provider policies subcollection" do
    let(:provider) { ems }

    it "query Provider policies with no policies defined" do
      test_no_policy_query(api_provider_policies_url(nil, provider))
    end

    it "query Provider policy profiles with no policy profiles defined" do
      test_no_policy_profile_query(api_provider_policy_profiles_url(nil, provider))
    end

    it "query Provider policies with one policy defined" do
      test_single_policy_query(provider, api_provider_policies_url(nil, provider))
    end

    it "query Provider policies with multiple policies defined" do
      test_multiple_policy_query(provider, api_provider_policies_url(nil, provider))
    end

    it "query Provider policy profiles" do
      test_policy_profile_query(provider, api_provider_policy_profiles_url(nil, provider))
    end
  end

  context "Host policies subcollection" do
    it "query Host policies with no policies defined" do
      test_no_policy_query(api_host_policies_url(nil, host))
    end

    it "query Host policy profiles with no policy profiles defined" do
      test_no_policy_profile_query(api_host_policy_profiles_url(nil, host))
    end

    it "query Host policies with one policy defined" do
      test_single_policy_query(host, api_host_policies_url(nil, host))
    end

    it "query Host policies with multiple policies defined" do
      test_multiple_policy_query(host, api_host_policies_url(nil, host))
    end

    it "query Host policy profiles" do
      test_policy_profile_query(host, api_host_policy_profiles_url(nil, host))
    end
  end

  context "Resource Pool policies subcollection" do
    let(:rp) { FactoryBot.create(:resource_pool, :name => "Resource Pool 1") }

    it "query Resource Pool policies with no policies defined" do
      test_no_policy_query(api_resource_pool_policies_url(nil, rp))
    end

    it "query Resource Pool policy profiles with no policy profiles defined" do
      test_no_policy_profile_query(api_resource_pool_policy_profiles_url(nil, rp))
    end

    it "query Resource Pool policies with one policy defined" do
      test_single_policy_query(rp, api_resource_pool_policies_url(nil, rp))
    end

    it "query Resource Pool policies with multiple policies defined" do
      test_multiple_policy_query(rp, api_resource_pool_policies_url(nil, rp))
    end

    it "query Resource Pool policy profiles" do
      test_policy_profile_query(rp, api_resource_pool_policy_profiles_url(nil, rp))
    end
  end

  context "Cluster policies subcollection" do
    let(:cluster) do
      FactoryBot.create(:ems_cluster,
                         :name => "Cluster 1", :ext_management_system => ems, :hosts => [host], :vms => [])
    end

    it "query Cluster policies with no policies defined" do
      test_no_policy_query(api_cluster_policies_url(nil, cluster))
    end

    it "query Cluster policy profiles with no policy profiles defined" do
      test_no_policy_profile_query(api_cluster_policy_profiles_url(nil, cluster))
    end

    it "query Cluster policies with one policy defined" do
      test_single_policy_query(cluster, api_cluster_policies_url(nil, cluster))
    end

    it "query Cluster policies with multiple policies defined" do
      test_multiple_policy_query(cluster, api_cluster_policies_url(nil, cluster))
    end

    it "query Cluster policy profiles" do
      test_policy_profile_query(cluster, api_cluster_policy_profiles_url(nil, cluster))
    end
  end

  context "Vms policies subcollection" do
    let(:vm)  { FactoryBot.create(:vm) }

    it "query Vm policies with no policies defined" do
      test_no_policy_query(api_vm_policies_url(nil, vm))
    end

    it "query Vm policy profiles with no policy profiles defined" do
      test_no_policy_profile_query(api_vm_policy_profiles_url(nil, vm))
    end

    it "query Vm policies with one policy defined" do
      test_single_policy_query(vm, api_vm_policies_url(nil, vm))
    end

    it "query Vm policies with multiple policies defined" do
      test_multiple_policy_query(vm, api_vm_policies_url(nil, vm))
    end

    it "query Vm policy profiles" do
      test_policy_profile_query(vm, api_vm_policy_profiles_url(nil, vm))
    end

    it "query Vm policy profiles and related policies" do
      test_policy_profile_policies_query(vm, api_vm_policy_profiles_url(nil, vm))
    end
  end

  context "Template policies subcollection" do
    let(:template)  do
      FactoryBot.create(:miq_template,
                         :name => "Template 1", :vendor => "vmware", :location => "template_1.vmtx")
    end

    it "query Template policies with no policies defined" do
      test_no_policy_query(api_template_policies_url(nil, template))
    end

    it "query Template policy profiles with no policy profiles defined" do
      test_no_policy_profile_query(api_template_policy_profiles_url(nil, template))
    end

    it "query Template policies with one policy defined" do
      test_single_policy_query(template, api_template_policies_url(nil, template))
    end

    it "query Template policies with multiple policies defined" do
      test_multiple_policy_query(template, api_template_policies_url(nil, template))
    end

    it "query Template policy profile" do
      test_policy_profile_query(template, api_template_policy_profiles_url(nil, template))
    end
  end

  context "Policy CRUD actions" do
    let(:action) { FactoryBot.create(:miq_action) }
    let(:conditions) { FactoryBot.create_list(:condition, 2) }
    let(:event) { FactoryBot.create(:miq_event_definition) }
    let(:miq_policy) { FactoryBot.create(:miq_policy) }
    let(:miq_policy_contents) do
      {"policy_contents" => [{'event_id' => event.id,
                              "actions"  => [{"action_id" => action.id, "opts" => { :qualifier => "failure" }}] }]}
    end
    let(:sample_policy) do
      {
        "description"    => "sample policy",
        "name"           => "sample policy",
        "mode"           => "compliance",
        "towhat"         => "ExtManagementSystem",
        "conditions_ids" => [conditions.first.id, conditions.second.id],
      }
    end

    it "creates new policy" do
      api_basic_authorize collection_action_identifier(:policies, :create)
      post(api_policies_url, :params => sample_policy.merge!(miq_policy_contents))
      policy = MiqPolicy.find(response.parsed_body["results"].first["id"])
      expect(response.parsed_body["results"].first["name"]).to eq("sample policy")
      expect(response.parsed_body["results"].first["towhat"]).to eq("ExtManagementSystem")
      expect(policy).to be_truthy
      expect(policy.conditions.count).to eq(2)
      expect(policy.actions.count).to eq(1)
      expect(policy.events.count).to eq(1)
      expect(response).to have_http_status(:ok)
    end

    it "shouldn't creates new policy with missing params" do
      api_basic_authorize collection_action_identifier(:policies, :create)
      post(api_policies_url, :params => sample_policy)
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]["message"]).to include("#{miq_policy_contents.keys.join(", ")} must be specified when creating")
    end

    describe "POST /api/policies/:id with 'delete' action" do
      it "can delete a policy with appropriate role" do
        api_basic_authorize(action_identifier(:policies, :delete))
        policy = FactoryBot.create(:miq_policy)

        expect { post(api_policy_url(nil, policy), :params => { :action => "delete" }) }.to change(MiqPolicy, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it "will not delete a policy without an appropriate role" do
        api_basic_authorize
        policy = FactoryBot.create(:miq_policy)

        expect { post(api_policy_url(nil, policy), :params => { :action => "delete" }) }.not_to change(MiqPolicy, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /api/policies with 'delete' action" do
      it "can delete a policy with appropriate role" do
        api_basic_authorize(collection_action_identifier(:policies, :delete))
        policy = FactoryBot.create(:miq_policy)

        expect do
          post(api_policies_url, :params => { :action => "delete", :resources => [{:id => policy.id}] })
        end.to change(MiqPolicy, :count).by(-1)

        expect(response.parsed_body).to include("results" => [a_hash_including("success" => true)])
        expect(response).to have_http_status(:ok)
      end

      it "will not delete a policy without an appropriate role" do
        api_basic_authorize
        policy = FactoryBot.create(:miq_policy)

        expect do
          post(api_policies_url, :params => { :action => "delete", :resources => [{:id => policy.id}] })
        end.not_to change(MiqPolicy, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "DELETE /api/policies/:id" do
      it "can delete a policy with appropriate role" do
        api_basic_authorize(action_identifier(:policies, :delete, :resource_actions, :delete))
        policy = FactoryBot.create(:miq_policy)

        expect { delete(api_policy_url(nil, policy)) }.to change(MiqPolicy, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it "will not delete a policy without an appropriate role" do
        api_basic_authorize
        policy = FactoryBot.create(:miq_policy)

        expect { delete(api_policy_url(nil, policy)) }.not_to change(MiqPolicy, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    it "edits policy actions events and conditions" do
      api_basic_authorize collection_action_identifier(:policies, :edit)
      miq_policy.conditions << conditions
      expect(miq_policy.conditions.count).to eq(2)
      expect(miq_policy.actions.count).to eq(0)
      expect(miq_policy.events.count).to eq(0)
      post(api_policy_url(nil, miq_policy), :params => gen_request(:edit, miq_policy_contents.merge('conditions_ids' => [])))
      policy = MiqPolicy.find(response.parsed_body["id"])
      expect(response).to have_http_status(:ok)
      expect(policy.actions.count).to eq(1)
      expect(policy.events.count).to eq(1)
      expect(miq_policy.conditions.count).to eq(0)
    end

    it "edits just the description" do
      api_basic_authorize collection_action_identifier(:policies, :edit)
      expect(miq_policy.description).to_not eq("BAR")
      post(api_policy_url(nil, miq_policy), :params => gen_request(:edit, :description => "BAR"))
      policy = MiqPolicy.find(response.parsed_body["id"])
      expect(response).to have_http_status(:ok)
      expect(policy.description).to eq("BAR")
    end
  end
end
