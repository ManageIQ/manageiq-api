RSpec.shared_examples "simulate policy action" do |model, factory, event|
  let(:target1)            { FactoryBot.create(factory) }
  let(:target2)            { FactoryBot.create(factory) }
  let(:invalid_target_url) { send("api_#{model}_url", nil, ApplicationRecord.id_in_region(999_999, ApplicationRecord.my_region_number)) }
  let(:target1_url)        { send("api_#{model}_url", nil, target1) }
  let(:target2_url)        { send("api_#{model}_url", nil, target2) }
  let(:collection_type)    { model.pluralize.to_sym }
  let(:collection_url)     { send("api_#{model.pluralize}_url") }
  let!(:event_definition)  { FactoryBot.create(:miq_event_definition, :name => event) }

  it "to an invalid #{model}" do
    api_basic_authorize action_identifier(collection_type, :simulate_policy)

    post(invalid_target_url, :params => {:action => :simulate_policy, :event => event})

    expect(response).to have_http_status(:not_found)
  end

  it "to an invalid #{model} without appropriate role" do
    api_basic_authorize

    post(invalid_target_url, :params => {:action => :simulate_policy, :event => event})

    expect(response).to have_http_status(:forbidden)
  end

  it "to a single #{model}" do
    api_basic_authorize action_identifier(collection_type, :simulate_policy)

    post(target1_url, :params => {:action => :simulate_policy, :event => event})

    expect_single_action_result(:success => true, :message => /Simulating policy for #{model.camelize} id: #{target1.id} .*/i, :href => target1_url, :task => true)
  end

  it "to a single #{model} without appropriate role" do
    api_basic_authorize

    post(target1_url, :params => {:action => :simulate_policy, :event => event})

    expect(response).to have_http_status(:forbidden)
  end

  it "to multipe #{model.pluralize} with resources" do
    api_basic_authorize collection_action_identifier(collection_type, :simulate_policy)

    post(collection_url, :params => {:action => :simulate_policy, :resources => [{:href => target1_url, :event => event}, {:href => target2_url, :event => event}]})

    expected = {
      "results" => a_collection_containing_exactly(
        a_hash_including(
          "message"   => a_string_matching(/Simulating policy for #{model.camelize} id: #{target1.id}/i),
          "task_id"   => a_kind_of(String),
          "task_href" => a_string_matching(api_tasks_url),
          "success"   => true,
          "href"      => target1_url
        ),
        a_hash_including(
          "message"   => a_string_matching(/Simulating policy for #{model.camelize} id: #{target2.id}/i),
          "task_id"   => a_kind_of(String),
          "task_href" => a_string_matching(api_tasks_url),
          "success"   => true,
          "href"      => target2_url
        )
      )
    }

    expect(response.parsed_body).to include(expected)
    expect(response).to have_http_status(:ok)
  end

  it "to multipe #{model.pluralize} with targets" do
    api_basic_authorize collection_action_identifier(collection_type, :simulate_policy)

    post(collection_url, :params => {:action => :simulate_policy, :event => event, :targets => [{:href => target1_url}, {:id => target2.id}]})

    expected = {
      "message"   => a_string_matching(/Simulating policy on event #{event} for targets/i),
      "task_id"   => a_kind_of(String),
      "task_href" => a_string_matching(api_tasks_url),
      "success"   => true
    }

    expect(response.parsed_body).to match(expected)
    expect(response).to have_http_status(:ok)
  end

  it "to multiple #{model.pluralize} without appropriate role" do
    api_basic_authorize

    post(collection_url, :params => {:action => :simulate_policy, :resources => [{:href => target1_url, :event => event}, {:href => target2_url, :event => event}]})

    expect(response).to have_http_status(:forbidden)
  end
end
