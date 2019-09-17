#
# Rest API Request Tests - Service Requests specs
#
# - Query provision_dialog from service_requests
#     GET /api/service_requests/:id?attributes=provision_dialog
#
# - Query provision_dialog from services
#     GET /api/services/:id?attributes=provision_dialog
#
describe "Service Requests API" do
  let(:provision_dialog1)    { FactoryBot.create(:dialog, :label => "ProvisionDialog1") }
  let(:retirement_dialog2)   { FactoryBot.create(:dialog, :label => "RetirementDialog2") }

  let(:provision_ra) { FactoryBot.create(:resource_action, :action => "Provision",  :dialog => provision_dialog1) }
  let(:retire_ra)    { FactoryBot.create(:resource_action, :action => "Retirement", :dialog => retirement_dialog2) }
  let(:template)     { FactoryBot.create(:service_template, :name => "ServiceTemplate") }

  let(:service_request) do
    FactoryBot.create(:service_template_provision_request,
                       :requester   => @user,
                       :source_id   => template.id,
                       :source_type => template.class.name)
  end

  let(:request_task) { FactoryBot.create(:miq_request_task, :miq_request => service_request) }
  let(:service) { FactoryBot.create(:service, :name => "Service", :miq_request_task => request_task) }

  def expect_result_to_have_provision_dialog
    expect_result_to_have_keys(%w(id href provision_dialog))
    provision_dialog = response.parsed_body["provision_dialog"]
    expect(provision_dialog).to be_kind_of(Hash)
    expect(provision_dialog).to have_key("label")
    expect(provision_dialog).to have_key("dialog_tabs")
    expect(provision_dialog["label"]).to eq(provision_dialog1.label)
  end

  def expect_result_to_have_user_email(email)
    expect(response).to have_http_status(:ok)
    expect_result_to_have_keys(%w(id href user))
    expect(response.parsed_body["user"]["email"]).to eq(email)
  end

  describe "Service Requests query" do
    before do
      template.resource_actions = [provision_ra, retire_ra]
      api_basic_authorize action_identifier(:service_requests, :read, :resource_actions, :get)
    end

    it "can return the provision_dialog" do
      get api_service_request_url(nil, service_request), :params => { :attributes => "provision_dialog" }

      expect_result_to_have_provision_dialog
    end

    it "can return the request's user.email" do
      @user.update!(:email => "admin@api.net")
      get api_service_request_url(nil, service_request), :params => { :attributes => "user.email" }

      expect_result_to_have_user_email(@user.email)
    end
  end

  describe "Service query" do
    before do
      template.resource_actions = [provision_ra, retire_ra]
      api_basic_authorize action_identifier(:services, :read, :resource_actions, :get)
    end

    it "can return the provision_dialog" do
      get api_service_url(nil, service), :params => { :attributes => "provision_dialog" }

      expect_result_to_have_provision_dialog
    end

    it "can return the request's user.email" do
      @user.update!(:email => "admin@api.net")
      get api_service_url(nil, service), :params => { :attributes => "user.email" }

      expect_result_to_have_user_email(@user.email)
    end
  end

  context "Service requests approval" do
    let(:svcreq1) do
      FactoryBot.create(:service_template_provision_request,
                         :requester   => @user,
                         :source_id   => template.id,
                         :source_type => template.class.name)
    end
    let(:svcreq2) do
      FactoryBot.create(:service_template_provision_request,
                         :requester   => @user,
                         :source_id   => template.id,
                         :source_type => template.class.name)
    end
    let(:svcreq1_url)  { api_service_request_url(nil, svcreq1) }
    let(:svcreq2_url)  { api_service_request_url(nil, svcreq2) }

    it "supports approving a request" do
      api_basic_authorize collection_action_identifier(:service_requests, :approve)

      post(svcreq1_url, :params => gen_request(:approve, :reason => "approve reason"))

      expected_msg = "Service request #{svcreq1.id} approved"
      expect_single_action_result(:success => true, :message => expected_msg, :href => api_service_request_url(nil, svcreq1))
    end

    it "supports denying a request" do
      api_basic_authorize collection_action_identifier(:service_requests, :approve)

      post(svcreq2_url, :params => gen_request(:deny, :reason => "deny reason"))

      expected_msg = "Service request #{svcreq2.id} denied"
      expect_single_action_result(:success => true, :message => expected_msg, :href => api_service_request_url(nil, svcreq2))
    end

    it "supports approving multiple requests" do
      api_basic_authorize collection_action_identifier(:service_requests, :approve)

      post(api_service_requests_url, :params => gen_request(:approve, [{"href" => svcreq1_url, "reason" => "approve reason"},
                                                                       {"href" => svcreq2_url, "reason" => "approve reason"}]))

      expected = {
        "results" => a_collection_containing_exactly(
          {
            "message" => a_string_matching(/Service request #{svcreq1.id} approved/i),
            "success" => true,
            "href"    => api_service_request_url(nil, svcreq1)
          },
          {
            "message" => a_string_matching(/Service request #{svcreq2.id} approved/i),
            "success" => true,
            "href"    => api_service_request_url(nil, svcreq2)
          }
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports denying multiple requests" do
      api_basic_authorize collection_action_identifier(:service_requests, :approve)

      post(api_service_requests_url, :params => gen_request(:deny, [{"href" => svcreq1_url, "reason" => "deny reason"},
                                                                    {"href" => svcreq2_url, "reason" => "deny reason"}]))

      expected = {
        "results" => a_collection_containing_exactly(
          {
            "message" => a_string_matching(/Service request #{svcreq1.id} denied/i),
            "success" => true,
            "href"    => api_service_request_url(nil, svcreq1)
          },
          {
            "message" => a_string_matching(/Service request #{svcreq2.id} denied/i),
            "success" => true,
            "href"    => api_service_request_url(nil, svcreq2)
          }
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  context "authorization" do
    it "is forbidden for a user without appropriate role" do
      api_basic_authorize

      get api_service_requests_url

      expect(response).to have_http_status(:forbidden)
    end

    it "does not list another user's requests" do
      other_user = FactoryBot.create(:user)
      FactoryBot.create(:service_template_provision_request,
                         :requester   => other_user,
                         :source_id   => template.id,
                         :source_type => template.class.name)
      api_basic_authorize collection_action_identifier(:service_requests, :read, :get)

      get api_service_requests_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("name" => "service_requests", "count" => 1, "subcount" => 0)
    end

    it "does not show another user's request" do
      other_user = FactoryBot.create(:user)
      service_request = FactoryBot.create(:service_template_provision_request,
                                           :requester   => other_user,
                                           :source_id   => template.id,
                                           :source_type => template.class.name)
      api_basic_authorize collection_action_identifier(:service_requests, :read, :get)

      get api_service_request_url(nil, service_request)

      expected = {
        "error" => a_hash_including(
          "message" => /Couldn't find ServiceTemplateProvisionRequest/
        )
      }
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to include(expected)
    end

    it "a user can list their own requests" do
      _service_request = FactoryBot.create(:service_template_provision_request,
                                            :requester   => @user,
                                            :source_id   => template.id,
                                            :source_type => template.class.name)
      api_basic_authorize collection_action_identifier(:service_requests, :read, :get)

      get api_service_requests_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("name" => "service_requests", "count" => 1, "subcount" => 1)
    end

    it "a user can show their own request" do
      service_request = FactoryBot.create(:service_template_provision_request,
                                           :requester   => @user,
                                           :source_id   => template.id,
                                           :source_type => template.class.name)
      api_basic_authorize collection_action_identifier(:service_requests, :read, :get)

      get api_service_request_url(nil, service_request)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("id"   => service_request.id.to_s,
                                              "href" => api_service_request_url(nil, service_request))
    end

    it "lists all the service requests if you are admin" do
      @group.miq_user_role = @role = FactoryBot.create(:miq_user_role, :features => %w(miq_request_approval))
      other_user = FactoryBot.create(:user)
      service_request_1 = FactoryBot.create(:service_template_provision_request,
                                             :requester   => other_user,
                                             :source_id   => template.id,
                                             :source_type => template.class.name)
      service_request_2 = FactoryBot.create(:service_template_provision_request,
                                             :requester   => @user,
                                             :source_id   => template.id,
                                             :source_type => template.class.name)
      api_basic_authorize collection_action_identifier(:service_requests, :read, :get)

      get api_service_requests_url

      expected = {
        "count"     => 2,
        "subcount"  => 2,
        "resources" => a_collection_containing_exactly(
          {"href" => api_service_request_url(nil, service_request_1)},
          {"href" => api_service_request_url(nil, service_request_2)},
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "an admin can see another user's request" do
      @group.miq_user_role = @role = FactoryBot.create(:miq_user_role, :features => %w(miq_request_approval))
      other_user = FactoryBot.create(:user)
      service_request = FactoryBot.create(:service_template_provision_request,
                                           :requester   => other_user,
                                           :source_id   => template.id,
                                           :source_type => template.class.name)
      api_basic_authorize collection_action_identifier(:service_requests, :read, :get)

      get api_service_request_url(nil, service_request)

      expected = {
        "id"   => service_request.id.to_s,
        "href" => api_service_request_url(nil, service_request)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'Service requests deletion' do
    it 'forbids deletion without an appropriate role' do
      api_basic_authorize

      post(api_service_request_url(nil, service_request), :params => { :action => 'delete' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can delete a single service request resource' do
      api_basic_authorize collection_action_identifier(:service_requests, :delete)

      post(api_service_request_url(nil, service_request), :params => { :action => 'delete' })

      expected = {
        'success' => true,
        'message' => "service_requests id: #{service_request.id} deleting"
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can delete multiple service requests' do
      service_request_2 = FactoryBot.create(:service_template_provision_request,
                                             :requester   => @user,
                                             :source_id   => template.id,
                                             :source_type => template.class.name)
      api_basic_authorize collection_action_identifier(:service_requests, :delete)

      post(
        api_service_requests_url,
        :params => {
          :action    => 'delete',
          :resources => [
            { :id => service_request.id },
            { :id => service_request_2.id }
          ]
        }
      )

      expected = {
        'results' => a_collection_including(
          a_hash_including('success' => true,
                           'message' => "service_requests id: #{service_request.id} deleting"),
          a_hash_including('success' => true,
                           'message' => "service_requests id: #{service_request_2.id} deleting")
        )
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can delete a service request via DELETE' do
      api_basic_authorize collection_action_identifier(:service_requests, :delete)

      delete(api_service_request_url(nil, service_request))

      expect(response).to have_http_status(:no_content)
    end

    it 'forbids service request DELETE without an appropriate role' do
      api_basic_authorize

      delete(api_service_request_url(nil, service_request))

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'Add Approver' do
    it 'can add a single approver' do
      service_request.miq_approvals << FactoryBot.create(:miq_approval)
      user = FactoryBot.create(:user)
      api_basic_authorize collection_action_identifier(:service_requests, :add_approver)

      expect do
        post(api_service_request_url(nil, service_request), :params => { :action => 'add_approver', :user_id => user.id })
      end.to change(MiqApproval, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => service_request.id.to_s)
    end

    it 'can add approvers to multiple service requests' do
      service_request.miq_approvals << FactoryBot.create(:miq_approval)
      user = FactoryBot.create(:user)
      service_request_2 = FactoryBot.create(:service_template_provision_request,
                                             :requester   => @user,
                                             :source_id   => template.id,
                                             :source_type => template.class.name)
      service_request_2.miq_approvals << FactoryBot.create(:miq_approval)
      api_basic_authorize collection_action_identifier(:service_requests, :add_approver)

      expected = {
        'results' => a_collection_including(
          a_hash_including('id' => service_request.id.to_s),
          a_hash_including('id' => service_request_2.id.to_s)
        )
      }
      expect do
        post(
          api_service_requests_url,
          :params => {
            :action    => 'add_approver',
            :resources => [
              { :id => service_request.id, :user_id => user.id },
              { :id => service_request_2.id, :user_id => user.id }
            ]
          }
        )
      end.to change(MiqApproval, :count).by(2)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids adding an approver without an appropriate role' do
      api_basic_authorize

      post(api_service_requests_url, :params => { :action => 'add_approver' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'supports user reference hash with id' do
      service_request.miq_approvals << FactoryBot.create(:miq_approval)
      user = FactoryBot.create(:user)
      api_basic_authorize collection_action_identifier(:service_requests, :add_approver)

      expect do
        post(api_service_request_url(nil, service_request), :params => { :action => 'add_approver', :user => { :id => user.id } })
      end.to change(MiqApproval, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => service_request.id.to_s)
    end

    it 'supports user reference hash with href' do
      service_request.miq_approvals << FactoryBot.create(:miq_approval)
      user = FactoryBot.create(:user)
      api_basic_authorize collection_action_identifier(:service_requests, :add_approver)

      expect do
        post(
          api_service_request_url(nil, service_request),
          :params => {
            :action => 'add_approver',
            :user   => {:href => api_user_url(nil, user)}
          }
        )
      end.to change(MiqApproval, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => service_request.id.to_s)
    end

    it 'raises an error if no user is supplied' do
      api_basic_authorize collection_action_identifier(:service_requests, :add_approver)

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => 'Cannot add approver - Must specify a valid user_id or user'
        )
      }
      post(api_service_request_url(nil, service_request), :params => { :action => 'add_approver' })
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'Remove Approver' do
    it 'can remove a single approver' do
      user = FactoryBot.create(:user)
      service_request.miq_approvals << FactoryBot.create(:miq_approval, :approver => user)
      api_basic_authorize collection_action_identifier(:service_requests, :add_approver)

      expect do
        post(api_service_request_url(nil, service_request), :params => { :action => 'remove_approver', :user_id => user.id })
      end.to change(MiqApproval, :count).by(-1)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => service_request.id.to_s)
    end

    it 'can remove approvers to multiple service requests' do
      user = FactoryBot.create(:user)
      service_request2 = FactoryBot.create(:service_template_provision_request,
                                            :requester   => @user,
                                            :source_id   => template.id,
                                            :source_type => template.class.name)
      service_request.miq_approvals << FactoryBot.create(:miq_approval, :approver => user)
      service_request2.miq_approvals << FactoryBot.create(:miq_approval, :approver => user)
      api_basic_authorize collection_action_identifier(:service_requests, :add_approver)

      expected = {
        'results' => a_collection_including(
          a_hash_including('id' => service_request.id.to_s),
          a_hash_including('id' => service_request2.id.to_s)
        )
      }
      expect do
        post(
          api_service_requests_url,
          :params => {
            :action    => 'remove_approver',
            :resources => [
              { :id => service_request.id, :user_id => user.id },
              { :id => service_request2.id, :user_id => user.id }
            ]
          }
        )
      end.to change(MiqApproval, :count).by(-2)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids adding an approver without an appropriate role' do
      api_basic_authorize

      post(api_service_requests_url, :params => { :action => 'remove_approver' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'supports user reference hash with href' do
      user = FactoryBot.create(:user)
      service_request.miq_approvals << FactoryBot.create(:miq_approval, :approver => user)
      api_basic_authorize collection_action_identifier(:service_requests, :add_approver)

      expect do
        post(
          api_service_request_url(nil, service_request),
          :params => {
            :action => 'remove_approver',
            :user   => { :href => api_user_url(nil, user)}
          }
        )
      end.to change(MiqApproval, :count).by(-1)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => service_request.id.to_s)
    end

    it 'raises an error if no user is supplied' do
      api_basic_authorize collection_action_identifier(:service_requests, :add_approver)

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => 'Cannot remove approver - Must specify a valid user_id or user'
        )
      }
      post(api_service_request_url(nil, service_request), :params => { :action => 'remove_approver' })
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end

    it 'does not raise error if incorrect user is supplied' do
      user = FactoryBot.create(:user)
      service_request.miq_approvals << FactoryBot.create(:miq_approval)
      api_basic_authorize collection_action_identifier(:service_requests, :add_approver)

      post(api_service_request_url(nil, service_request), :params => { :action => 'remove_approver', :user_id => user.id })
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => service_request.id.to_s)
    end
  end

  context 'service request update' do
    it 'forbids service request update without an appropriate role' do
      service_request = FactoryBot.create(:service_template_provision_request,
                                           :requester => @user,
                                           :options   => {:foo => "bar"})
      api_basic_authorize

      post(api_service_request_url(nil, service_request), :params => { :action => "edit", :options => {:baz => "qux"} })

      expect(response).to have_http_status(:forbidden)
    end

    it 'updates a single service request' do
      service_request = FactoryBot.create(:service_template_provision_request,
                                           :requester => @user,
                                           :options   => {:foo => "bar"})
      api_basic_authorize(action_identifier(:service_requests, :edit))

      post(api_service_request_url(nil, service_request), :params => { :action => "edit", :options => {:baz => "qux"} })

      expected = {
        "id"      => service_request.id.to_s,
        "options" => a_hash_including("foo" => "bar")
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'updates multiple service requests' do
      service_request, service_request2 = FactoryBot.create_list(:service_template_provision_request,
                                                                  2,
                                                                  :requester => @user,
                                                                  :options   => {:foo => "bar"})
      api_basic_authorize collection_action_identifier(:service_requests, :edit)

      post(
        api_service_requests_url,
        :params => {
          :action    => "edit",
          :resources => [
            {:id => service_request.id, :options => {:baz => "qux"}},
            {:id => service_request2.id, :options => {:quux => "quuz"}}
          ]
        }
      )

      expected = {
        "results" => a_collection_including(
          a_hash_including("options" => a_hash_including("foo" => "bar", "baz" => "qux")),
          a_hash_including("options" => a_hash_including("foo" => "bar", "quux" => "quuz"))
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'Tasks subcollection' do
    let(:task) { FactoryBot.create(:miq_request_task, :miq_request => service_request) }
    let(:options) { { "a" => 1 } }
    let(:params) { gen_request(:edit, :options => options) }

    it 'does not allow direct edit of task' do
      api_basic_authorize

      post(api_request_task_url(nil, task), :params => params)

      expect(response).to have_http_status(:bad_request)
    end

    it 'allows access to underlying service task' do
      api_basic_authorize collection_action_identifier(:service_requests, :read, :get)

      get(api_request_request_task_url(nil, service_request, task))

      expect(response).to have_http_status(:ok)
    end

    it 'allows edit of task as a subcollection of service request' do
      tasks_url = api_request_request_task_url(nil, service_request, task)
      api_basic_authorize subcollection_action_identifier(:service_requests, :request_tasks, :edit)
      post(tasks_url, :params => params)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['options']).to match(hash_including(options))
      expect(task.reload.options.keys).to all(be_kind_of(Symbol))
    end

    context "SubResource#cancel" do
      let(:resource_1_response) { {"success" => true, "message" => "RequestTask #{resource_1.id} canceled"} }
      let(:resource_2_response) { {"success" => true, "message" => "RequestTask #{resource_2.id} canceled"} }
      include_context "SubResource#cancel", [:service_request, :request_task], :service_template_transformation_plan_request, :service_template_transformation_plan_task
    end
  end

  context "Resource#cancel" do
    let(:resource_1_response) { {"success" => true, "message" => "ServiceTemplateProvisionRequest #{resource_1.id} canceled", "href" => instance_url(resource_1)} }
    let(:resource_2_response) { {"success" => true, "message" => "ServiceTemplateProvisionRequest #{resource_2.id} canceled", "href" => instance_url(resource_2)} }
    include_context "Resource#cancel", "service_request", :service_template_transformation_plan_request
  end
end
