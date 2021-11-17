RSpec.shared_context "SubResource#cancel" do |ns, request_factory, factory, success = true|
  let(:base_namespace) { ns.first.to_s.pluralize.to_sym }
  let(:sub_namespace)  { ns[1].to_s.pluralize.to_sym }
  let(:namespace)      { ns.join("_") }
  let(:collection_url) { "api_#{namespace.pluralize}_url" }
  let(:instance_url)   { "api_#{namespace}_url" }
  let(:request)        { FactoryBot.create(request_factory, :with_api_user) }
  let(:resource_1)     { FactoryBot.create(factory, :with_api_user) }
  let(:resource_2)     { FactoryBot.create(factory, :with_api_user) }

  context "single instance cancel" do
    it "unauthorized" do
      expect_forbidden_request { post(send(instance_url, nil, request, resource_1.id), :params => gen_request(:cancel)) }
    end

    it "authorized" do
      api_basic_authorize subcollection_action_identifier(base_namespace, sub_namespace, :cancel)
      post(send(instance_url, nil, request, resource_1.id), :params => gen_request(:cancel))

      expect_single_action_result(:success => success, :message => /Cancel operation is not supported/)
    end
  end

  context "multiple instance cancel" do
    it "unauthorized" do
      expect_forbidden_request { post(send(collection_url, nil, request), :params => gen_request(:cancel, [{:id => resource_1.id}, {:id => resource_2.id}])) }
    end

    it "authorized" do
      api_basic_authorize subcollection_action_identifier(base_namespace, sub_namespace, :cancel)
      post(send(collection_url, nil, request), :params => gen_request(:cancel, [{:id => resource_1.id}, {:id => resource_2.id}]))

      expect(response).to have_http_status(:ok)
      expect_multiple_action_result(2, :success => success, :message => /Cancel operation is not supported/)
    end
  end
end
