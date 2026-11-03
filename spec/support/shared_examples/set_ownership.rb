def resource_type_name(collection_name)
  collection_name.to_s.singularize
end

RSpec.shared_examples "endpoints with set_ownership action" do |collection_name, factory_name|
  def expect_set_ownership_success(object, href, user = nil, group = nil)
    expect_single_action_result(:success => true, :message => "setting ownership", :href => href)
    expect(object.reload.evm_owner).to eq(user)  if user
    expect(object.reload.miq_group).to eq(group) if group
  end

  let(:resource)              { FactoryBot.create(factory_name) }
  let(:method_resource_url)   { "api_#{resource_type_name(collection_name)}_url" }
  let(:method_collection_url) { "api_#{collection_name}_url" }

  it "to an invalid #{resource_type_name(collection_name)}" do
    api_basic_authorize action_identifier(collection_name, :set_ownership)

    post(send(method_resource_url, nil, 999_999), :params => gen_request(:set_ownership, "owner" => {"id" => 1}))

    expect(response).to have_http_status(:not_found)
  end

  subject { send(method_resource_url, nil, resource) }

  it "without appropriate action role" do
    api_basic_authorize

    post(subject, :params => gen_request(:set_ownership, "owner" => {"id" => 1}))

    expect(response).to have_http_status(:forbidden)
  end

  it "with missing owner or group" do
    api_basic_authorize action_identifier(collection_name, :set_ownership)

    post(subject, :params => gen_request(:set_ownership))

    expect_bad_request("Must specify an owner or group")
  end

  it "with invalid owner" do
    api_basic_authorize action_identifier(collection_name, :set_ownership)

    post(subject, :params => gen_request(:set_ownership, "owner" => {"id" => 999_999}))

    expect_single_action_result(:success => false, :message => /.*/, :href => subject)
  end

  it "to a #{resource_type_name(collection_name)}" do
    api_basic_authorize action_identifier(collection_name, :set_ownership)

    post(subject, :params => gen_request(:set_ownership, "owner" => {"userid" => @user.userid}))

    expect_set_ownership_success(resource, subject, @user)
  end

  it "by owner name to a #{resource_type_name(collection_name)}" do
    api_basic_authorize action_identifier(collection_name, :set_ownership)

    post(subject, :params => gen_request(:set_ownership, "owner" => {"name" => @user.name}))

    expect_set_ownership_success(resource, subject, @user)
  end

  it "by owner href to a #{resource_type_name(collection_name)}" do
    api_basic_authorize action_identifier(collection_name, :set_ownership)

    post(subject, :params => gen_request(:set_ownership, "owner" => {"href" => api_user_url(nil, @user)}))

    expect_set_ownership_success(resource, subject, @user)
  end

  it "by owner id to a #{resource_type_name(collection_name)}" do
    api_basic_authorize action_identifier(collection_name, :set_ownership)

    post(subject, :params => gen_request(:set_ownership, "owner" => {"id" => @user.id}))

    expect_set_ownership_success(resource, subject, @user)
  end

  it "by group id to a #{resource_type_name(collection_name)}" do
    api_basic_authorize action_identifier(collection_name, :set_ownership)

    post(subject, :params => gen_request(:set_ownership, "group" => {"id" => @group.id}))

    expect_set_ownership_success(resource, subject, nil, @group)
  end

  it "by group description to a #{resource_type_name(collection_name)}" do
    api_basic_authorize action_identifier(collection_name, :set_ownership)

    post(subject, :params => gen_request(:set_ownership, "group" => {"description" => @group.description}))

    expect_set_ownership_success(resource, subject, nil, @group)
  end

  it "with owner and group to a #{resource_type_name(collection_name)}" do
    api_basic_authorize action_identifier(collection_name, :set_ownership)

    post(subject, :params => gen_request(:set_ownership, "owner" => {"userid" => @user.userid}))

    expect_set_ownership_success(resource, subject, @user)
  end

  # A cleared group is nil, or the tenant's default group for models that include TenancyMixin.
  context "clearing ownership" do
    before { resource.update!(:evm_owner => @user, :miq_group => @group) }

    it "clears the owner with a blank owner id" do
      api_basic_authorize action_identifier(collection_name, :set_ownership)

      post(subject, :params => gen_request(:set_ownership, "owner" => {"id" => ""}, "group" => {"id" => @group.id.to_s}))

      expect_single_action_result(:success => true, :message => "setting ownership", :href => subject)
      expect(resource.reload.evm_owner).to be_nil
      expect(resource.miq_group).to eq(@group)
    end

    it "clears the group with a blank group id" do
      api_basic_authorize action_identifier(collection_name, :set_ownership)

      post(subject, :params => gen_request(:set_ownership, "owner" => {"id" => @user.id.to_s}, "group" => {"id" => ""}))

      expect_single_action_result(:success => true, :message => "setting ownership", :href => subject)
      expect(resource.reload.evm_owner).to eq(@user)
      expect(resource.miq_group).not_to eq(@group)
    end

    it "clears both with blank owner and group ids" do
      api_basic_authorize action_identifier(collection_name, :set_ownership)

      post(subject, :params => gen_request(:set_ownership, "owner" => {"id" => ""}, "group" => {"id" => ""}))

      expect_single_action_result(:success => true, :message => "setting ownership", :href => subject)
      expect(resource.reload.evm_owner).to be_nil
      expect(resource.miq_group).not_to eq(@group)
    end

    it "leaves an omitted owner or group unchanged" do
      api_basic_authorize action_identifier(collection_name, :set_ownership)

      post(subject, :params => gen_request(:set_ownership, "owner" => {"id" => ""}))

      expect(resource.reload.evm_owner).to be_nil
      expect(resource.miq_group).to eq(@group)
    end
  end

  it "to multiple #{collection_name}" do
    api_basic_authorize action_identifier(collection_name, :set_ownership)

    resource1 = FactoryBot.create(factory_name)
    resource2 = FactoryBot.create(factory_name)

    resource_urls = [send(method_resource_url, nil, resource1), send(method_resource_url, nil, resource2)]
    post(send(method_collection_url), :params => gen_request(:set_ownership, {"owner" => {"userid" => @user.userid}}, *resource_urls))

    expect_multiple_action_result(2)
    expect_result_resources_to_include_hrefs("results", [send(method_resource_url, nil, resource1), send(method_resource_url, nil, resource2)])
    expect(resource1.reload.evm_owner).to eq(@user)
    expect(resource2.reload.evm_owner).to eq(@user)
  end
end
