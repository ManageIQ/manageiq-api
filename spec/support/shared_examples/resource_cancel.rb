RSpec.shared_context "Resource#cancel" do |ns, factory|
  let(:collection_identifier) { namespace.pluralize.to_sym }
  let(:collection_url)        { send("api_#{collection_identifier}_url") }
  let(:namespace)             { ns } # ns is not available from #instance_url method, but namespace is.
  let(:resource_1)            { FactoryGirl.create(factory, :with_api_user) }
  let(:resource_2)            { FactoryGirl.create(factory, :with_api_user) }

  def instance_url(instance)
    send("api_#{namespace}_url", nil, instance)
  end

  context "on a single instance" do
    it "unauthorized" do
      expect_forbidden_request { post(instance_url(resource_1), :params => gen_request(:cancel)) }
    end

    it "authorized" do
      api_basic_authorize collection_action_identifier(collection_identifier, :cancel)

      post(instance_url(resource_1), :params => gen_request(:cancel))

      expect_single_action_result(resource_1_response)
    end
  end

  context "on multiple instances" do
    it "unauthorized" do
      expect_forbidden_request { post(collection_url, :params => gen_request(:cancel, [{"href" => instance_url(resource_1)}, {"href" => instance_url(resource_2)}])) }
    end

    it "authorized" do
      api_basic_authorize collection_action_identifier(collection_identifier, :cancel)

      post(collection_url, :params => gen_request(:cancel, [{"href" => instance_url(resource_1)}, {"href" => instance_url(resource_2)}]))

      expect(response.parsed_body).to include("results" => a_collection_containing_exactly(resource_1_response, resource_2_response))
      expect(response).to have_http_status(:ok)
    end
  end
end
