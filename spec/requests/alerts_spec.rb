describe "Alerts API" do
  it "forbids access to alerts list without an appropriate role" do
    api_basic_authorize
    get(api_alerts_url)
    expect(response).to have_http_status(:forbidden)
  end

  it "reads 2 alerts as a collection" do
    api_basic_authorize collection_action_identifier(:alerts, :read, :get)
    alert_statuses = FactoryBot.create_list(:miq_alert_status, 2)
    get(api_alerts_url)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(
      "name"      => "alerts",
      "count"     => 2,
      "subcount"  => 2,
      "resources" => [
        {
          "href" => api_alert_url(nil, alert_statuses[0])
        },
        {
          "href" => api_alert_url(nil, alert_statuses[1])
        }
      ]
    )
  end

  it "forbids access to an alert resource without an appropriate role" do
    api_basic_authorize
    alert_status = FactoryBot.create(:miq_alert_status)
    get(api_alert_url(nil, alert_status))
    expect(response).to have_http_status(:forbidden)
  end

  it "reads an alert as a resource" do
    api_basic_authorize action_identifier(:alerts, :read, :resource_actions, :get)
    alert_status = FactoryBot.create(:miq_alert_status)
    get(api_alert_url(nil, alert_status))
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(
      "href" => api_alert_url(nil, alert_status),
      "id"   => alert_status.id.to_s
    )
  end

  context "alert_actions subcollection" do
    let(:alert) { FactoryBot.create(:miq_alert_status) }
    let(:assignee) { FactoryBot.create(:user) }
    let(:expected_assignee) do
      {
        'results' => a_collection_containing_exactly(
          a_hash_including("assignee_id" => assignee.id.to_s)
        )
      }
    end

    it "forbids access to alerts actions subcollection without an appropriate role" do
      FactoryBot.create(
        :miq_alert_status_action,
        :miq_alert_status => alert,
        :user             => FactoryBot.create(:user)
      )
      api_basic_authorize
      get(api_alert_alert_actions_url(nil, alert))
      expect(response).to have_http_status(:forbidden)
    end

    it "reads an alert action as a sub collection under an alert" do
      api_basic_authorize subcollection_action_identifier(:alerts, :alert_actions, :read, :get)
      alert_action = FactoryBot.create(
        :miq_alert_status_action,
        :miq_alert_status => alert,
        :user             => FactoryBot.create(:user)
      )
      get(api_alert_alert_actions_url(nil, alert))
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "name"      => "alert_actions",
        "count"     => 1,
        "subcount"  => 1,
        "resources" => [
          {
            "href" => api_alert_alert_action_url(nil, alert, alert_action)
          }
        ]
      )
    end

    it "forbids creation of an alert action under alerts without an appropriate role" do
      api_basic_authorize
      post(
        api_alert_alert_actions_url(nil, alert),
        :params => {
          "action_type" => "comment",
          "comment"     => "comment text"
        }
      )
      expect(response).to have_http_status(:forbidden)
    end

    it "creates an alert action under an alert" do
      attributes = {
        "action_type" => "comment",
        "comment"     => "comment text",
      }
      api_basic_authorize subcollection_action_identifier(:alerts, :alert_actions, :create, :post)
      post(api_alert_alert_actions_url(nil, alert), :params => attributes)
      expect(response).to have_http_status(:ok)
      expected = {
        "results" => [
          a_hash_including(attributes)
        ]
      }
      expect(response.parsed_body).to include(expected)
    end

    it "creates an alert action on the current user" do
      user = FactoryBot.create(:user)
      attributes = {
        "action_type" => "comment",
        "comment"     => "comment text",
        "user_id"     => user.id # should be ignored
      }
      api_basic_authorize subcollection_action_identifier(:alerts, :alert_actions, :create, :post)
      post(api_alert_alert_actions_url(nil, alert), :params => attributes)
      expect(response).to have_http_status(:ok)
      expected = {
        "results" => [
          a_hash_including(attributes.merge("user_id" => User.current_user.id.to_s))
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(user.id).not_to eq(User.current_user.id)
    end

    it "create an assignment alert action reference by id" do
      attributes = {
        "action_type" => "assign",
        "assignee"    => { "id" => assignee.id.to_s }
      }
      api_basic_authorize subcollection_action_identifier(:alerts, :alert_actions, :create, :post)
      post(api_alert_alert_actions_url(nil, alert), :params => attributes)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected_assignee)
    end

    it "create an assignment alert action reference by href" do
      attributes = {
        "action_type" => "assign",
        "assignee"    => { "href" => api_user_url(nil, assignee) }
      }
      api_basic_authorize subcollection_action_identifier(:alerts, :alert_actions, :create, :post)
      post(api_alert_alert_actions_url(nil, alert), :params => attributes)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected_assignee)
    end

    it "returns errors when creating an invalid alert" do
      api_basic_authorize subcollection_action_identifier(:alerts, :alert_actions, :create, :post)
      post(
        api_alert_alert_actions_url(nil, alert),
        :params => { "action_type" => "assign"}
      )
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include_error_with_message(
        "Failed to add a new alert action resource - MiqAlertStatusAction: Assignee can't be blank"
      )
    end

    it "reads an alert action as a resource under an alert" do
      api_basic_authorize subcollection_action_identifier(:alerts, :alert_actions, :read, :get)
      user = FactoryBot.create(:user)
      alert_action = FactoryBot.create(
        :miq_alert_status_action,
        :miq_alert_status => alert,
        :user             => user
      )
      get(api_alert_alert_action_url(nil, alert, alert_action))
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "href"        => api_alert_alert_action_url(nil, alert, alert_action),
        "id"          => alert_action.id.to_s,
        "action_type" => alert_action.action_type,
        "user_id"     => user.id.to_s,
        "comment"     => alert_action.comment,
      )
    end
  end
end
