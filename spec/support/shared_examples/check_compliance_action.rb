RSpec.shared_examples "a check compliance action" do |model, factory, event_class|
  let(:instance)             { FactoryBot.create(factory) }
  let(:instance1)            { FactoryBot.create(factory) }
  let(:instance2)            { FactoryBot.create(factory) }
  let(:invalid_instance_url) { send("api_#{model}_url", nil, ApplicationRecord.id_in_region(999_999, ApplicationRecord.my_region_number)) }
  let(:instance_url)         { send("api_#{model}_url", nil, instance) }
  let(:instance1_url)        { send("api_#{model}_url", nil, instance1) }
  let(:instance2_url)        { send("api_#{model}_url", nil, instance2) }
  let(:collection_type)      { model.pluralize.to_sym }
  let(:collection_url)       { send("api_#{model.pluralize}_url") }
  let(:model_text)           { model.singularize.titleize }

  let!(:event_definition) { FactoryBot.create(:miq_event_definition, :name => "#{event_class.downcase}_compliance_check") }
  let!(:policy_content)   do
    content = FactoryBot.create(:miq_policy_content, :qualifier => "failure", :failure_sequence => 1)
    content.miq_action = FactoryBot.create(:miq_action, :name => "compliance_failed", :action_type => "default")
    content.miq_event_definition = event_definition
    content
  end

  let!(:compliance_policy) do
    policy = FactoryBot.create(:miq_policy, :mode => "compliance", :towhat => event_class, :description => "check_compliance", :active => true)
    policy.conditions << FactoryBot.create(:condition)
    policy.miq_policy_contents << policy_content
    policy.sync_events([event_definition])
    policy
  end

  it "to an invalid #{model}" do
    api_basic_authorize action_identifier(collection_type, :check_compliance)

    post(invalid_instance_url, :params => gen_request(:check_compliance))

    expect(response).to have_http_status(:not_found)
  end

  it "to an invalid #{model} without appropriate role" do
    api_basic_authorize

    post(invalid_instance_url, :params => gen_request(:check_compliance))

    expect(response).to have_http_status(:forbidden)
  end

  it "to a single #{model} without compliance policies assigned" do
    api_basic_authorize action_identifier(collection_type, :check_compliance)

    post(instance_url, :params => gen_request(:check_compliance))

    expect_bad_request(/Check Compliance for #{model_text} id: #{instance.id} .* No compliance policies assigned/i)
  end

  it "to a single #{model} with a compliance policy" do
    api_basic_authorize action_identifier(collection_type, :check_compliance)

    instance.add_policy(compliance_policy)

    post(instance_url, :params => gen_request(:check_compliance))

    expect_single_action_result(:success => true, :message => /Check Compliance for #{model_text} id: #{instance.id}/i, :href => instance_url, :task => true)
  end

  it "to multiple #{model.pluralize} without appropriate role" do
    api_basic_authorize

    post(collection_url, :params => gen_request(:check_compliance, [{"href" => instance1_url}, {"href" => instance2_url}]))

    expect(response).to have_http_status(:forbidden)
  end

  it "to multiple #{model.pluralize}" do
    api_basic_authorize collection_action_identifier(collection_type, :check_compliance)

    instance1.add_policy(compliance_policy)

    post(collection_url, :params => gen_request(:check_compliance, [{"href" => instance1_url}, {"href" => instance2_url}]))

    expected = {
      "results" => a_collection_containing_exactly(
        a_hash_including(
          "message"   => a_string_matching(/Check Compliance for #{model_text} id: #{instance1.id}/i),
          "task_id"   => a_kind_of(String),
          "task_href" => a_string_matching(api_tasks_url),
          "success"   => true,
          "href"      => instance1_url
        ),
        a_hash_including(
          "message" => a_string_matching(/Check Compliance for #{model_text} id: #{instance2.id}.* No compliance policies assigned/i),
          "success" => false,
          "href"    => instance2_url
        )
      )
    }

    expect(response.parsed_body).to include(expected)
    expect(response).to have_http_status(:ok)
  end
end
