#
# Rest API Request Tests - Automation Requests specs
#
# - Create single automation request    /api/automation_requests    normal POST
# - Create single automation request    /api/automation_requests    action "create"
# - Create multiple automation requests /api/automation_requests    action "create"
#
# - Approve single automation request      /api/automation_requests/:id    action "approve"
# - Approve multiple automation requests   /api/automation_requests        action "approve"
# - Deny single automation request         /api/automation_requests/:id    action "deny"
# - Deny multiple automation requests      /api/automation_requests        action "deny"
#
describe "Automation Requests API" do
  describe "Automation Requests" do
    before { FactoryBot.create(:user_admin, :userid => 'admin') }

    let(:approver) { FactoryBot.create(:user_miq_request_approver) }
    let(:single_automation_request) do
      {
        "uri_parts"  => {"
          namespace" => "System", "class" => "Request", "instance" => "InspectME", "message" => "create"
         },
        "parameters" => {"var1" => "xyzzy", "var2" => 1024, "var3" => true, "schedule_time" => Time.now.utc + 10.days },
        "requester"  => {"user_name" => approver.userid, "auto_approve" => true}
      }
    end
    let(:expected_hash) do
      {"approval_state" => "approved", "type" => "AutomationRequest", "request_type" => "automation", "status" => "Ok"}
    end

    it "filters the list of automation requests by requester" do
      other_user = FactoryBot.create(:user)
      _automation_request1 = FactoryBot.create(:automation_request, :requester => other_user)
      automation_request2 = FactoryBot.create(:automation_request, :requester => @user)
      api_basic_authorize collection_action_identifier(:automation_requests, :read, :get)

      get api_automation_requests_url

      expected = {
        "count"     => 1,
        "subcount"  => 1,
        "resources" => a_collection_containing_exactly(
          "href" => api_automation_request_url(nil, automation_request2),
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "lists all the automation requests if you are admin" do
      @group.miq_user_role = @role = FactoryBot.create(:miq_user_role, :features => %w(miq_request_approval))
      other_user = FactoryBot.create(:user)
      automation_request1 = FactoryBot.create(:automation_request, :requester => other_user)
      automation_request2 = FactoryBot.create(:automation_request, :requester => @user)
      api_basic_authorize collection_action_identifier(:automation_requests, :read, :get)

      get api_automation_requests_url

      expected = {
        "count"     => 2,
        "subcount"  => 2,
        "resources" => a_collection_containing_exactly(
          {"href" => api_automation_request_url(nil, automation_request1)},
          {"href" => api_automation_request_url(nil, automation_request2)},
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "restricts access to automation requests to requester" do
      other_user = FactoryBot.create(:user)
      automation_request = FactoryBot.create(:automation_request, :requester => other_user)
      api_basic_authorize action_identifier(:automation_requests, :read, :resource_actions, :get)

      get api_automation_request_url(nil, automation_request)

      expect(response).to have_http_status(:not_found)
    end

    it "an admin can see another user's request" do
      @group.miq_user_role = @role = FactoryBot.create(:miq_user_role, :features => %w(miq_request_approval))
      other_user = FactoryBot.create(:user)
      automation_request = FactoryBot.create(:automation_request, :requester => other_user)
      api_basic_authorize action_identifier(:automation_requests, :read, :resource_actions, :get)

      get api_automation_request_url(nil, automation_request)

      expected = {
        "id"   => automation_request.id.to_s,
        "href" => api_automation_request_url(nil, automation_request)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "supports single request with normal post" do
      api_basic_authorize

      post(api_automation_requests_url, :params => single_automation_request)

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", %w(id approval_state type request_type status options))
      expect_results_to_match_hash("results", [expected_hash])

      task_id = response.parsed_body["results"].first["id"]
      expect(AutomationRequest.exists?(task_id)).to be_truthy
    end

    it "supports single request with create action" do
      api_basic_authorize

      post(api_automation_requests_url, :params => gen_request(:create, single_automation_request))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", %w(id approval_state type request_type status options))
      expect_results_to_match_hash("results", [expected_hash])

      task_id = response.parsed_body["results"].first["id"]
      expect(AutomationRequest.exists?(task_id)).to be_truthy
    end

    it "supports multiple requests" do
      api_basic_authorize

      post(api_automation_requests_url, :params => gen_request(:create, [single_automation_request, single_automation_request]))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", %w(id approval_state type request_type status options))
      expect_results_to_match_hash("results", [expected_hash, expected_hash])

      task_id1, task_id2 = response.parsed_body["results"].collect { |r| r["id"] }
      expect(AutomationRequest.exists?(task_id1)).to be_truthy
      expect(AutomationRequest.exists?(task_id2)).to be_truthy
    end
  end

  describe "automation request update" do
    it 'forbids provision request update without an appropriate role' do
      automation_request = FactoryBot.create(:automation_request, :requester => @user, :options => {:foo => "bar"})
      api_basic_authorize

      post(api_automation_request_url(nil, automation_request), :params => { :action => "edit", :options => {:baz => "qux"} })

      expect(response).to have_http_status(:forbidden)
    end

    it 'updates a single provision request' do
      automation_request = FactoryBot.create(:automation_request, :requester => @user, :options => {:foo => "bar"})
      api_basic_authorize(action_identifier(:automation_requests, :edit))

      post(api_automation_request_url(nil, automation_request), :params => { :action => "edit", :options => {:baz => "qux"} })

      expected = {
        "id"      => automation_request.id.to_s,
        "options" => a_hash_including("foo" => "bar", "baz" => "qux")
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'updates multiple provision requests' do
      automation_request, automation_request2 = FactoryBot.create_list(:automation_request,
                                                                        2,
                                                                        :requester => @user,
                                                                        :options   => {:foo => "bar"})
      api_basic_authorize collection_action_identifier(:service_requests, :edit)

      post(
        api_automation_requests_url,
        :params => {
          :action    => "edit",
          :resources => [
            {:id => automation_request.id, :options => {:baz => "qux"}},
            {:id => automation_request2.id, :options => {:quux => "quuz"}}
          ]
        }
      )

      expected = {
        'results' => a_collection_containing_exactly(
          a_hash_including("options" => a_hash_including("foo" => "bar", "baz" => "qux")),
          a_hash_including("options" => a_hash_including("foo" => "bar", "quux" => "quuz"))
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "Automation requests approval" do
    let(:template)      { FactoryBot.create(:template_amazon) }
    let(:request_body)  { {:requester => @user, :source_type => 'VmOrTemplate', :source_id => template.id} }
    let(:request1)      { FactoryBot.create(:automation_request, request_body) }
    let(:request1_url)  { api_automation_request_url(nil, request1) }
    let(:request2)      { FactoryBot.create(:automation_request, request_body) }
    let(:request2_url)  { api_automation_request_url(nil, request2) }

    it "supports approving a request" do
      api_basic_authorize collection_action_identifier(:automation_requests, :approve)

      post(request1_url, :params => gen_request(:approve, :reason => "approve reason"))

      expected_msg = "Approving Automation Request id: #{request1.id}"
      expect_single_action_result(:success => true, :message => expected_msg, :href => api_automation_request_url(nil, request1))
    end

    it "supports denying a request" do
      api_basic_authorize collection_action_identifier(:automation_requests, :deny)

      post(request2_url, :params => gen_request(:deny, :reason => "deny reason"))

      expected_msg = "Denying Automation Request id: #{request2.id}"
      expect_single_action_result(:success => true, :message => expected_msg, :href => api_automation_request_url(nil, request2))
    end

    it "supports approving multiple requests" do
      api_basic_authorize collection_action_identifier(:automation_requests, :approve)

      post(api_automation_requests_url, :params => gen_request(:approve, [{"href" => request1_url, "reason" => "approve reason"},
                                                                          {"href" => request2_url, "reason" => "approve reason"}]))

      expected = {
        "results" => a_collection_containing_exactly(
          {
            "message" => a_string_matching(/Approving Automation Request id: #{request1.id}/i),
            "success" => true,
            "href"    => api_automation_request_url(nil, request1)
          },
          {
            "message" => a_string_matching(/Approving Automation Request id: #{request2.id}/i),
            "success" => true,
            "href"    => api_automation_request_url(nil, request2)
          }
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports denying multiple requests" do
      api_basic_authorize collection_action_identifier(:automation_requests, :deny)

      post(api_automation_requests_url, :params => gen_request(:deny, [{"href" => request1_url, "reason" => "deny reason"},
                                                                       {"href" => request2_url, "reason" => "deny reason"}]))

      expected = {
        "results" => a_collection_containing_exactly(
          {
            "message" => a_string_matching(/Denying Automation Request id: #{request1.id}/i),
            "success" => true,
            "href"    => api_automation_request_url(nil, request1)
          },
          {
            "message" => a_string_matching(/Denying Automation Request id: #{request2.id}/i),
            "success" => true,
            "href"    => api_automation_request_url(nil, request2)
          }
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  context 'Tasks subcollection' do
    let(:automation_request) { FactoryBot.create(:automation_request, :requester => @user) }
    let(:task) { FactoryBot.create(:miq_request_task, :miq_request => automation_request) }
    let(:options) { { 'a' => 1 } }
    let(:params) { gen_request(:edit, :options => options) }

    it 'does not allow direct edit of automation task' do
      api_basic_authorize

      post(api_request_task_url(nil, task), :params => params)

      expect(response).to have_http_status(:bad_request)
    end

    it 'allows access to underlying automation task' do
      api_basic_authorize collection_action_identifier(:automation_requests, :read, :get)

      get(api_request_request_task_url(nil, automation_request, task))

      expect(response).to have_http_status(:ok)
    end

    it 'allows edit of task as a subcollection of automation request' do
      tasks_url = api_request_request_task_url(nil, automation_request, task)
      api_basic_authorize subcollection_action_identifier(:automation_requests, :request_tasks, :edit)
      post(tasks_url, :params => params)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['options']).to match(hash_including(options))
      expect(task.reload.options.keys).to all(be_kind_of(Symbol))
    end

    context "SubResource#cancel" do
      include_context "SubResource#cancel", [:automation_request, :request_task], :automation_request, :automation_task, false
    end
  end

  context "Resource#cancel" do
    include_context "Resource#cancel", "automation_request", :automation_request, false
  end
end
