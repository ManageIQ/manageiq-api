#
# REST API Request Tests - Policies and Policy Profiles Assignments
#
# Testing both assign and unassign actions for policies
# and policy profiles on the following collections
#   /api/vms/:id
#   /api/providers/:id
#   /api/hosts/:id
#   /api/resource_pool_clouds/:id
#   /api/resource_pool_infras/:id
#   /api/clusters/:id
#   /api/templates/:id
#
# Targeting as follows:
#   /api/:collection/:id/policies
#       and
#   /api/:collection/:id/policy_profiles
#
describe "Policies Assignment API" do
  let(:zone)       { FactoryBot.create(:zone, :name => "api_zone") }
  let(:provider)   { FactoryBot.create(:ems_vmware, :zone => zone) }
  let(:host)       { FactoryBot.create(:host) }
  let(:cluster)    do
    FactoryBot.create(:ems_cluster, :ext_management_system => provider, :hosts => [host], :vms => [])
  end
  let(:rpc)         { FactoryBot.create(:resource_pool, :name => "Resource Pool 1", :type => ManageIQ::Providers::CloudManager::ResourcePool) }
  let(:rpi)         { FactoryBot.create(:resource_pool, :name => "Resource Pool 1", :type => ManageIQ::Providers::InfraManager::ResourcePool) }
  let(:vm)         { FactoryBot.create(:vm) }
  let(:template)   do
    FactoryBot.create(:miq_template, :name => "Tmpl 1", :vendor => "vmware", :location => "tmpl_1.vmtx")
  end

  let(:p1)  { FactoryBot.create(:miq_policy, :description => "Policy 1") }
  let(:p2)  { FactoryBot.create(:miq_policy, :description => "Policy 2") }
  let(:p3)  { FactoryBot.create(:miq_policy, :description => "Policy 3") }

  let(:ps1) { FactoryBot.create(:miq_policy_set, :description => "Policy Set 1") }
  let(:ps2) { FactoryBot.create(:miq_policy_set, :description => "Policy Set 2") }

  before do
    # Creating:  policy_set_1 = [policy_1, policy_2]  and  policy_set_2 = [policy_3]

    ps1.add_member(p1)
    ps1.add_member(p2)

    ps2.add_member(p3)
  end

  def test_policy_assign_no_role(api_object_policies_url)
    api_basic_authorize

    post(api_object_policies_url, :params => gen_request(:assign))

    expect(response).to have_http_status(:forbidden)
  end

  def test_policy_assign_invalid_policy(api_object_policies_url, collection, subcollection)
    api_basic_authorize subcollection_action_identifier(collection, subcollection, :assign)

    post(api_object_policies_url, :params => gen_request(:assign, :href => "/api/#{subcollection}/999999"))

    expect(response).to have_http_status(:not_found)
  end

  def test_policy_assign_invalid_policy_guid(object_url, api_object_policies_url, collection, subcollection)
    api_basic_authorize subcollection_action_identifier(collection, subcollection, :assign)

    post(api_object_policies_url, :params => gen_request(:assign, :guid => "xyzzy"))

    expect(response).to have_http_status(:bad_request)
    results_hash = [{"success" => false, "href" => object_url, "message" => /must specify a valid/i}]
    expect_results_to_match_hash("results", results_hash)
  end

  def test_assign_multiple_policies(object_url, api_object_policies_url, collection, subcollection, options = {})
    api_basic_authorize subcollection_action_identifier(collection, subcollection, :assign)

    object = options[:object]
    policies = options[:policies]

    post(api_object_policies_url, :params => gen_request(:assign, policies.collect { |p| {:guid => p.guid} }))

    expect_multiple_action_result(policies.size)
    sc_prefix = subcollection.to_s.singularize
    results_hash = policies.collect do |policy|
      {"success" => true, "href" => object_url, "#{sc_prefix}_href" => %r{/api/#{subcollection}/#{policy.id.to_s}}}
    end
    expect_results_to_match_hash("results", results_hash)
    expect(object.get_policies.size).to eq(policies.size)
    expect(object.get_policies.collect(&:guid)).to match_array(policies.collect(&:guid))
  end

  def test_policy_unassign_no_role(api_object_policies_url)
    api_basic_authorize

    post(api_object_policies_url, :params => gen_request(:unassign))

    expect(response).to have_http_status(:forbidden)
  end

  def test_policy_unassign_invalid_policy(api_object_policies_url, collection, subcollection)
    api_basic_authorize subcollection_action_identifier(collection, subcollection, :unassign)

    post(api_object_policies_url, :params => gen_request(:unassign, :href => "/api/#{subcollection}/999999"))

    expect(response).to have_http_status(:not_found)
  end

  def test_policy_unassign_invalid_policy_guid(object_url, api_object_policies_url, collection, subcollection)
    api_basic_authorize subcollection_action_identifier(collection, subcollection, :unassign)

    post(api_object_policies_url, :params => gen_request(:unassign, :guid => "xyzzy"))

    expect(response).to have_http_status(:bad_request)
    results_hash = [{"success" => false, "href" => object_url, "message" => /must specify a valid/i}]
    expect_results_to_match_hash("results", results_hash)
  end

  def test_unassign_multiple_policies(api_object_policies_url, collection, subcollection, options = {})
    api_basic_authorize subcollection_action_identifier(collection, subcollection, :unassign)

    object = options[:object]
    [p1, p2, p3].each { |p| object.add_policy(p) }
    post(api_object_policies_url, :params => gen_request(:unassign, [{:guid => p2.guid}, {:guid => p3.guid}]))
    object.reload

    expect_multiple_action_result(2)
    expect(object.get_policies.size).to eq(1)
    expect(object.get_policies.first.guid).to eq(p1.guid)
  end

  def test_unassign_multiple_policy_profiles(api_object_policies_url, collection, subcollection, options = {})
    api_basic_authorize subcollection_action_identifier(collection, subcollection, :unassign)

    object = options[:object]
    [ps1, ps2].each { |ps| object.add_policy(ps) }
    post(api_object_policies_url, :params => gen_request(:unassign, [{:guid => ps2.guid}]))

    expect_multiple_action_result(1)
    expect(object.get_policies.size).to eq(1)
    expect(object.get_policies.first.guid).to eq(ps1.guid)
  end

  context "Policy profile policies assignment" do
    it "adds Policies to a Policy Profile" do
      test_assign_multiple_policies(api_policy_profile_url(nil, ps2),
                                    api_policy_profile_policies_url(nil, ps2),
                                    :policy_profiles,
                                    :policies,
                                    :object   => ps2,
                                    :policies => [p1, p2, p3])
    end

    it "removes Policies from a Policy Profile" do
      test_unassign_multiple_policies(api_policy_profile_policies_url(nil, ps2), :policy_profiles, :policies, :object => ps2)
    end
  end

  context "Provider policies subcollection assignment" do
    it "assign Provider policy without approriate role" do
      test_policy_assign_no_role(api_provider_policies_url(nil, provider))
    end

    it "assign Provider policy with invalid href" do
      test_policy_assign_invalid_policy(api_provider_policies_url(nil, provider), :providers, :policies)
    end

    it "assign Provider policy with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_provider_url(nil, provider), api_provider_policies_url(nil, provider), :providers, :policies)
    end

    it "assign Provider multiple policies" do
      test_assign_multiple_policies(api_provider_url(nil, provider),
                                    api_provider_policies_url(nil, provider),
                                    :providers,
                                    :policies,
                                    :object   => provider,
                                    :policies => [p1, p2])
    end

    it "unassign Provider policy without approriate role" do
      test_policy_unassign_no_role(api_provider_policies_url(nil, provider))
    end

    it "unassign Provider policy with invalid href" do
      test_policy_unassign_invalid_policy(api_provider_policies_url(nil, provider), :providers, :policies)
    end

    it "unassign Provider policy with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_provider_url(nil, provider), api_provider_policies_url(nil, provider), :providers, :policies)
    end

    it "unassign Provider multiple policies" do
      test_unassign_multiple_policies(api_provider_policies_url(nil, provider), :providers, :policies, :object => provider)
    end
  end

  context "Provider policy profiles subcollection assignment" do
    it "assign Provider policy profile without approriate role" do
      test_policy_assign_no_role(api_provider_policy_profiles_url(nil, provider))
    end

    it "assign Provider policy profile with invalid href" do
      test_policy_assign_invalid_policy(api_provider_policy_profiles_url(nil, provider), :providers, :policy_profiles)
    end

    it "assign Provider policy profile with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_provider_url(nil, provider), api_provider_policy_profiles_url(nil, provider), :providers, :policy_profiles)
    end

    it "assign Provider multiple policy profiles" do
      test_assign_multiple_policies(api_provider_url(nil, provider),
                                    api_provider_policy_profiles_url(nil, provider),
                                    :providers,
                                    :policy_profiles,
                                    :object   => provider,
                                    :policies => [ps1, ps2])
    end

    it "unassign Provider policy profile without approriate role" do
      test_policy_unassign_no_role(api_provider_policy_profiles_url(nil, provider))
    end

    it "unassign Provider policy profile with invalid href" do
      test_policy_unassign_invalid_policy(api_provider_policy_profiles_url(nil, provider), :providers, :policy_profiles)
    end

    it "unassign Provider policy profile with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_provider_url(nil, provider),
                                               api_provider_policy_profiles_url(nil, provider),
                                               :providers,
                                               :policy_profiles)
    end

    it "unassign Provider multiple policy profiles" do
      test_unassign_multiple_policy_profiles(api_provider_policy_profiles_url(nil, provider),
                                             :providers,
                                             :policy_profiles,
                                             :object => provider)
    end
  end

  context "Host policies subcollection assignments" do
    it "assign Host policy without approriate role" do
      test_policy_assign_no_role(api_host_policies_url(nil, host))
    end

    it "assign Host policy with invalid href" do
      test_policy_assign_invalid_policy(api_host_policies_url(nil, host), :hosts, :policies)
    end

    it "assign Host policy with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_host_url(nil, host), api_host_policies_url(nil, host), :hosts, :policies)
    end

    it "assign Host multiple policies" do
      test_assign_multiple_policies(api_host_url(nil, host),
                                    api_host_policies_url(nil, host),
                                    :hosts,
                                    :policies,
                                    :object   => host,
                                    :policies => [p1, p2])
    end

    it "unassign Host policy without approriate role" do
      test_policy_unassign_no_role(api_host_policies_url(nil, host))
    end

    it "unassign Host policy with invalid href" do
      test_policy_unassign_invalid_policy(api_host_policies_url(nil, host), :hosts, :policies)
    end

    it "unassign Host policy with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_host_url(nil, host), api_host_policies_url(nil, host), :hosts, :policies)
    end

    it "unassign Host multiple policies" do
      test_unassign_multiple_policies(api_host_policies_url(nil, host), :hosts, :policies, :object => host)
    end
  end

  context "Host policy profiles subcollection assignments" do
    it "assign Host policy profile without approriate role" do
      test_policy_assign_no_role(api_host_policy_profiles_url(nil, host))
    end

    it "assign Host policy profile with invalid href" do
      test_policy_assign_invalid_policy(api_host_policy_profiles_url(nil, host), :hosts, :policy_profiles)
    end

    it "assign Host policy profile with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_host_url(nil, host), api_host_policy_profiles_url(nil, host), :hosts, :policy_profiles)
    end

    it "assign Host multiple policy profiles" do
      test_assign_multiple_policies(api_host_url(nil, host),
                                    api_host_policy_profiles_url(nil, host),
                                    :hosts,
                                    :policy_profiles,
                                    :object   => host,
                                    :policies => [ps1, ps2])
    end

    it "unassign Host policy profile without approriate role" do
      test_policy_unassign_no_role(api_host_policy_profiles_url(nil, host))
    end

    it "unassign Host policy profile with invalid href" do
      test_policy_unassign_invalid_policy(api_host_policy_profiles_url(nil, host), :hosts, :policy_profiles)
    end

    it "unassign Host policy profile with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_host_url(nil, host),
                                               api_host_policy_profiles_url(nil, host),
                                               :hosts,
                                               :policy_profiles)
    end

    it "unassign Host multiple policy profiles" do
      test_unassign_multiple_policy_profiles(api_host_policy_profiles_url(nil, host),
                                             :hosts,
                                             :policy_profiles,
                                             :object => host)
    end
  end

  context "Resource Pool Cloud policies subcollection assignments" do
    it "assign Resource Pool Cloud policy without appropriate role" do
      test_policy_assign_no_role(api_resource_pool_cloud_policies_url(nil, rpc))
    end

    it "assign Resource Pool Cloud policy with invalid href" do
      test_policy_assign_invalid_policy(api_resource_pool_cloud_policies_url(nil, rpc), :resource_pool_clouds, :policies)
    end

    it "assign Resource Pool Cloud policy with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_resource_pool_cloud_url(nil, rpc), api_resource_pool_cloud_policies_url(nil, rpc), :resource_pool_clouds, :policies)
    end

    it "assign Resource Pool Cloud multiple policies" do
      test_assign_multiple_policies(api_resource_pool_cloud_url(nil, rpc),
                                    api_resource_pool_cloud_policies_url(nil, rpc),
                                    :resource_pool_clouds,
                                    :policies,
                                    :object   => rpc,
                                    :policies => [p1, p2])
    end

    it "unassign Resource Pool Cloud policy without approriate role" do
      test_policy_unassign_no_role(api_resource_pool_cloud_policies_url(nil, rpc))
    end

    it "unassign Resource Pool Cloud policy with invalid href" do
      test_policy_unassign_invalid_policy(api_resource_pool_cloud_policies_url(nil, rpc), :resource_pool_clouds, :policies)
    end

    it "unassign Resource Pool Cloud policy with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_resource_pool_cloud_url(nil, rpc), api_resource_pool_cloud_policies_url(nil, rpc), :resource_pool_clouds, :policies)
    end

    it "unassign Resource Pool Cloud multiple policies" do
      test_unassign_multiple_policies(api_resource_pool_cloud_policies_url(nil, rpc), :resource_pool_clouds, :policies, :object => rpc)
    end
  end

  context "Resource Pool Cloud policy profiles subcollection assignments" do
    it "assign Resource Pool Cloud policy profile without approriate role" do
      test_policy_assign_no_role(api_resource_pool_cloud_policy_profiles_url(nil, rpc))
    end

    it "assign Resource Pool Cloud policy profile with invalid href" do
      test_policy_assign_invalid_policy(api_resource_pool_cloud_policy_profiles_url(nil, rpc), :resource_pool_clouds, :policy_profiles)
    end

    it "assign Resource Pool Cloud policy profile with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_resource_pool_cloud_url(nil, rpc), api_resource_pool_cloud_policy_profiles_url(nil, rpc), :resource_pool_clouds, :policy_profiles)
    end

    it "assign Resource Pool Cloud multiple policy profiles" do
      test_assign_multiple_policies(api_resource_pool_cloud_url(nil, rpc),
                                    api_resource_pool_cloud_policy_profiles_url(nil, rpc),
                                    :resource_pool_clouds,
                                    :policy_profiles,
                                    :object   => rpc,
                                    :policies => [ps1, ps2])
    end

    it "unassign Resource Pool Cloud policy profile without approriate role" do
      test_policy_unassign_no_role(api_resource_pool_cloud_policy_profiles_url(nil, rpc))
    end

    it "unassign Resource Pool Cloud policy profile with invalid href" do
      test_policy_unassign_invalid_policy(api_resource_pool_cloud_policy_profiles_url(nil, rpc), :resource_pool_clouds, :policy_profiles)
    end

    it "unassign Resource Pool Cloud policy profile with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_resource_pool_cloud_url(nil, rpc),
                                               api_resource_pool_cloud_policy_profiles_url(nil, rpc),
                                               :resource_pool_clouds,
                                               :policy_profiles)
    end

    it "unassign Resource Pool Cloud multiple policy profiles" do
      test_unassign_multiple_policy_profiles(api_resource_pool_cloud_policy_profiles_url(nil, rpc),
                                             :resource_pool_clouds,
                                             :policy_profiles,
                                             :object => rpc)
    end
  end

  context "Resource Pool Infra policies subcollection assignments" do
    it "assign Resource Pool Infra policy without appropriate role" do
      test_policy_assign_no_role(api_resource_pool_infra_policies_url(nil, rpi))
    end

    it "assign Resource Pool Infra policy with invalid href" do
      test_policy_assign_invalid_policy(api_resource_pool_infra_policies_url(nil, rpi), :resource_pool_infras, :policies)
    end

    it "assign Resource Pool Infra policy with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_resource_pool_infra_url(nil, rpi), api_resource_pool_infra_policies_url(nil, rpi), :resource_pool_infras, :policies)
    end

    it "assign Resource Pool Infra multiple policies" do
      test_assign_multiple_policies(api_resource_pool_infra_url(nil, rpi),
                                    api_resource_pool_infra_policies_url(nil, rpi),
                                    :resource_pool_infras,
                                    :policies,
                                    :object   => rpi,
                                    :policies => [p1, p2])
    end

    it "unassign Resource Pool Infra policy without approriate role" do
      test_policy_unassign_no_role(api_resource_pool_infra_policies_url(nil, rpi))
    end

    it "unassign Resource Pool Infra policy with invalid href" do
      test_policy_unassign_invalid_policy(api_resource_pool_infra_policies_url(nil, rpi), :resource_pool_infras, :policies)
    end

    it "unassign Resource Pool Infra policy with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_resource_pool_infra_url(nil, rpi), api_resource_pool_infra_policies_url(nil, rpi), :resource_pool_infras, :policies)
    end

    it "unassign Resource Pool Infra multiple policies" do
      test_unassign_multiple_policies(api_resource_pool_infra_policies_url(nil, rpi), :resource_pool_infras, :policies, :object => rpi)
    end
  end

  context "Resource Pool Infra policy profiles subcollection assignments" do
    it "assign Resource Pool Infra policy profile without approriate role" do
      test_policy_assign_no_role(api_resource_pool_infra_policy_profiles_url(nil, rpi))
    end

    it "assign Resource Pool Infra policy profile with invalid href" do
      test_policy_assign_invalid_policy(api_resource_pool_infra_policy_profiles_url(nil, rpi), :resource_pool_infras, :policy_profiles)
    end

    it "assign Resource Pool Infra policy profile with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_resource_pool_infra_url(nil, rpi), api_resource_pool_infra_policy_profiles_url(nil, rpi), :resource_pool_infras, :policy_profiles)
    end

    it "assign Resource Pool Infra multiple policy profiles" do
      test_assign_multiple_policies(api_resource_pool_infra_url(nil, rpi),
                                    api_resource_pool_infra_policy_profiles_url(nil, rpi),
                                    :resource_pool_infras,
                                    :policy_profiles,
                                    :object   => rpi,
                                    :policies => [ps1, ps2])
    end

    it "unassign Resource Pool Infra policy profile without approriate role" do
      test_policy_unassign_no_role(api_resource_pool_infra_policy_profiles_url(nil, rpi))
    end

    it "unassign Resource Pool Infra policy profile with invalid href" do
      test_policy_unassign_invalid_policy(api_resource_pool_infra_policy_profiles_url(nil, rpi), :resource_pool_infras, :policy_profiles)
    end

    it "unassign Resource Pool Infra policy profile with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_resource_pool_infra_url(nil, rpi),
                                               api_resource_pool_infra_policy_profiles_url(nil, rpi),
                                               :resource_pool_infras,
                                               :policy_profiles)
    end

    it "unassign Resource Pool Infra multiple policy profiles" do
      test_unassign_multiple_policy_profiles(api_resource_pool_infra_policy_profiles_url(nil, rpi),
                                             :resource_pool_infras,
                                             :policy_profiles,
                                             :object => rpi)
    end
  end

  context "Cluster policies subcollection assignments" do
    it "assign Cluster policy without approriate role" do
      test_policy_assign_no_role(api_cluster_policies_url(nil, cluster))
    end

    it "assign Cluster policy with invalid href" do
      test_policy_assign_invalid_policy(api_cluster_policies_url(nil, cluster), :clusters, :policies)
    end

    it "assign Cluster policy with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_cluster_url(nil, cluster), api_cluster_policies_url(nil, cluster), :clusters, :policies)
    end

    it "assign Cluster multiple policies" do
      test_assign_multiple_policies(api_cluster_url(nil, cluster),
                                    api_cluster_policies_url(nil, cluster),
                                    :clusters,
                                    :policies,
                                    :object   => cluster,
                                    :policies => [p1, p2])
    end

    it "unassign Cluster policy without approriate role" do
      test_policy_unassign_no_role(api_cluster_policies_url(nil, cluster))
    end

    it "unassign Cluster policy with invalid href" do
      test_policy_unassign_invalid_policy(api_cluster_policies_url(nil, cluster), :clusters, :policies)
    end

    it "unassign Cluster policy with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_cluster_url(nil, cluster), api_cluster_policies_url(nil, cluster), :clusters, :policies)
    end

    it "unassign Cluster multiple policies" do
      test_unassign_multiple_policies(api_cluster_policies_url(nil, cluster), :clusters, :policies, :object => cluster)
    end
  end

  context "Cluster policy profiles subcollection assignments" do
    it "assign Cluster policy profile without approriate role" do
      test_policy_assign_no_role(api_cluster_policy_profiles_url(nil, cluster))
    end

    it "assign Cluster policy profile with invalid href" do
      test_policy_assign_invalid_policy(api_cluster_policy_profiles_url(nil, cluster), :clusters, :policy_profiles)
    end

    it "assign Cluster policy profile with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_cluster_url(nil, cluster), api_cluster_policy_profiles_url(nil, cluster), :clusters, :policy_profiles)
    end

    it "assign Cluster multiple policy profiles" do
      test_assign_multiple_policies(api_cluster_url(nil, cluster),
                                    api_cluster_policy_profiles_url(nil, cluster),
                                    :clusters,
                                    :policy_profiles,
                                    :object   => cluster,
                                    :policies => [ps1, ps2])
    end

    it "unassign Cluster policy profile without approriate role" do
      test_policy_unassign_no_role(api_cluster_policy_profiles_url(nil, cluster))
    end

    it "unassign Cluster policy profile with invalid href" do
      test_policy_unassign_invalid_policy(api_cluster_policy_profiles_url(nil, cluster), :clusters, :policy_profiles)
    end

    it "unassign Cluster policy profile with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_cluster_url(nil, cluster),
                                               api_cluster_policy_profiles_url(nil, cluster),
                                               :clusters,
                                               :policy_profiles)
    end

    it "unassign Cluster multiple policy profiles" do
      test_unassign_multiple_policy_profiles(api_cluster_policy_profiles_url(nil, cluster),
                                             :clusters,
                                             :policy_profiles,
                                             :object => cluster)
    end
  end

  context "Vms policies subcollection assignments" do
    it "assign Vm policy without approriate role" do
      test_policy_assign_no_role(api_vm_policies_url(nil, vm))
    end

    it "assign Vm policy with invalid href" do
      test_policy_assign_invalid_policy(api_vm_policies_url(nil, vm), :vms, :policies)
    end

    it "assign Vm policy with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_vm_url(nil, vm), api_vm_policies_url(nil, vm), :vms, :policies)
    end

    it "assign Vm multiple policies" do
      test_assign_multiple_policies(api_vm_url(nil, vm),
                                    api_vm_policies_url(nil, vm),
                                    :vms,
                                    :policies,
                                    :object   => vm,
                                    :policies => [p1, p2])
    end

    it "unassign Vm policy without approriate role" do
      test_policy_unassign_no_role(api_vm_policies_url(nil, vm))
    end

    it "unassign Vm policy with invalid href" do
      test_policy_unassign_invalid_policy(api_vm_policies_url(nil, vm), :vms, :policies)
    end

    it "unassign Vm policy with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_vm_url(nil, vm), api_vm_policies_url(nil, vm), :vms, :policies)
    end

    it "unassign Vm multiple policies" do
      test_unassign_multiple_policies(api_vm_policies_url(nil, vm), :vms, :policies, :object => vm)
    end
  end

  context "Vms policy profiles subcollection assignments" do
    it "assign Vm policy profile without approriate role" do
      test_policy_assign_no_role(api_vm_policy_profiles_url(nil, vm))
    end

    it "assign Vm policy profile with invalid href" do
      test_policy_assign_invalid_policy(api_vm_policy_profiles_url(nil, vm), :vms, :policy_profiles)
    end

    it "assign Vm policy profile with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_vm_url(nil, vm), api_vm_policy_profiles_url(nil, vm), :vms, :policy_profiles)
    end

    it "assign Vm multiple policy profiles" do
      test_assign_multiple_policies(api_vm_url(nil, vm),
                                    api_vm_policy_profiles_url(nil, vm),
                                    :vms,
                                    :policy_profiles,
                                    :object   => vm,
                                    :policies => [ps1, ps2])
    end

    it "unassign Vm policy profile without approriate role" do
      test_policy_unassign_no_role(api_vm_policy_profiles_url(nil, vm))
    end

    it "unassign Vm policy profile with invalid href" do
      test_policy_unassign_invalid_policy(api_vm_policy_profiles_url(nil, vm), :vms, :policy_profiles)
    end

    it "unassign Vm policy profile with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_vm_url(nil, vm),
                                               api_vm_policy_profiles_url(nil, vm),
                                               :vms,
                                               :policy_profiles)
    end

    it "unassign Vm multiple policy profiles" do
      test_unassign_multiple_policy_profiles(api_vm_policy_profiles_url(nil, vm),
                                             :vms,
                                             :policy_profiles,
                                             :object => vm)
    end
  end

  context "Template policies subcollection assignments" do
    it "assign Template policy without approriate role" do
      test_policy_assign_no_role(api_template_policies_url(nil, template))
    end

    it "assign Template policy with invalid href" do
      test_policy_assign_invalid_policy(api_template_policies_url(nil, template), :templates, :policies)
    end

    it "assign Template policy with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_template_url(nil, template), api_template_policies_url(nil, template), :templates, :policies)
    end

    it "assign Template multiple policies" do
      test_assign_multiple_policies(api_template_url(nil, template),
                                    api_template_policies_url(nil, template),
                                    :templates,
                                    :policies,
                                    :object   => template,
                                    :policies => [p1, p2])
    end

    it "unassign Template policy without approriate role" do
      test_policy_unassign_no_role(api_template_policies_url(nil, template))
    end

    it "unassign Template policy with invalid href" do
      test_policy_unassign_invalid_policy(api_template_policies_url(nil, template), :templates, :policies)
    end

    it "unassign Template policy with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_template_url(nil, template), api_template_policies_url(nil, template), :templates, :policies)
    end

    it "unassign Template multiple policies" do
      test_unassign_multiple_policies(api_template_policies_url(nil, template), :templates, :policies, :object => template)
    end
  end

  context "Template policies subcollection assignments" do
    it "assign Template policy profile without approriate role" do
      test_policy_assign_no_role(api_template_policy_profiles_url(nil, template))
    end

    it "assign Template policy profile with invalid href" do
      test_policy_assign_invalid_policy(api_template_policy_profiles_url(nil, template), :templates, :policy_profiles)
    end

    it "assign Template policy profile with invalid guid" do
      test_policy_assign_invalid_policy_guid(api_template_url(nil, template), api_template_policy_profiles_url(nil, template), :templates, :policy_profiles)
    end

    it "assign Template multiple policy profiles" do
      test_assign_multiple_policies(api_template_url(nil, template),
                                    api_template_policy_profiles_url(nil, template),
                                    :templates,
                                    :policy_profiles,
                                    :object   => template,
                                    :policies => [ps1, ps2])
    end

    it "unassign Template policy profile without approriate role" do
      test_policy_unassign_no_role(api_template_policy_profiles_url(nil, template))
    end

    it "unassign Template policy profile with invalid href" do
      test_policy_unassign_invalid_policy(api_template_policy_profiles_url(nil, template), :templates, :policy_profiles)
    end

    it "unassign Template policy profile with invalid guid" do
      test_policy_unassign_invalid_policy_guid(api_template_url(nil, template),
                                               api_template_policy_profiles_url(nil, template),
                                               :templates,
                                               :policy_profiles)
    end

    it "unassign Template multiple policy profiles" do
      test_unassign_multiple_policy_profiles(api_template_policy_profiles_url(nil, template),
                                             :templates,
                                             :policy_profiles,
                                             :object => template)
    end
  end
end
