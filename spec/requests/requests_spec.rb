RSpec.describe "Requests API" do
  let(:template) { FactoryBot.create(:service_template, :name => "ServiceTemplate") }

  context "authorization" do
    it "is forbidden for a user without appropriate role" do
      api_basic_authorize

      get api_requests_url

      expect(response).to have_http_status(:forbidden)
    end

    it "does not list another user's requests" do
      other_user = FactoryBot.create(:user)
      FactoryBot.create(:service_template_provision_request,
                         :requester   => other_user,
                         :source_id   => template.id,
                         :source_type => template.class.name)
      api_basic_authorize collection_action_identifier(:requests, :read, :get)

      get api_requests_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("name" => "requests", "count" => 1, "subcount" => 0)
    end

    it "does not show another user's request" do
      other_user = FactoryBot.create(:user)
      service_request = FactoryBot.create(:service_template_provision_request,
                                           :requester   => other_user,
                                           :source_id   => template.id,
                                           :source_type => template.class.name)
      api_basic_authorize action_identifier(:requests, :read, :resource_actions, :get)

      get api_request_url(nil, service_request)

      expected = {
        "error" => a_hash_including(
          "message" => /Couldn't find MiqRequest/
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
      api_basic_authorize collection_action_identifier(:requests, :read, :get)

      get api_requests_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("name" => "requests", "count" => 1, "subcount" => 1)
    end

    it "a user can show their own request" do
      service_request = FactoryBot.create(:service_template_provision_request,
                                           :requester   => @user,
                                           :source_id   => template.id,
                                           :source_type => template.class.name)
      api_basic_authorize action_identifier(:requests, :read, :resource_actions, :get)

      get api_request_url(nil, service_request)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("id"   => service_request.id.to_s,
                                              "href" => api_request_url(nil, service_request))
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
      api_basic_authorize collection_action_identifier(:requests, :read, :get)

      get api_requests_url

      expected = {
        "count"     => 2,
        "subcount"  => 2,
        "resources" => a_collection_containing_exactly(
          {"href" => api_request_url(nil, service_request_1)},
          {"href" => api_request_url(nil, service_request_2)},
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
      api_basic_authorize action_identifier(:requests, :read, :resource_actions, :get)

      get api_request_url(nil, service_request)

      expected = {
        "id"   => service_request.id.to_s,
        "href" => api_request_url(nil, service_request)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "request creation" do
    it "is forbidden for a user to create a request without appropriate role" do
      api_basic_authorize

      post(api_requests_url, :params => gen_request(:create, :options => { :request_type => "service_reconfigure" }))

      expect(response).to have_http_status(:forbidden)
    end

    it "is forbidden for a user to create a request with a different request role" do
      api_basic_authorize :vm_reconfigure

      post(api_requests_url, :params => gen_request(:create, :options => { :request_type => "service_reconfigure" }))

      expect(response).to have_http_status(:forbidden)
    end

    it "fails if the request_type is missing" do
      api_basic_authorize

      post(api_requests_url, :params => gen_request(:create, :options => { :src_id => 4 }))

      expect_bad_request(/Invalid request - /)
    end

    it "fails if the request_type is unknown" do
      api_basic_authorize

      post(api_requests_url, :params => gen_request(:create,
                                                    :options => {
                                                      :request_type => "invalid_request"
                                                    }))

      expect_bad_request(/Invalid request - /)
    end

    it "fails if the request is missing a src_id" do
      api_basic_authorize :service_reconfigure

      post(api_requests_url, :params => gen_request(:create, :options => { :request_type => "service_reconfigure" }))

      expect_bad_request(/Could not create the request - /)
    end

    it "fails if the requester is invalid" do
      api_basic_authorize :service_reconfigure

      post(api_requests_url, :params => gen_request(:create,
                                                    :options   => {
                                                      :request_type => "service_reconfigure",
                                                      :src_id       => 4
                                                    },
                                                    :requester => { "user_name" => "invalid_user"}))

      expect_bad_request(/Unknown requester user_name invalid_user specified/)
    end

    it "succeed" do
      api_basic_authorize :service_reconfigure

      service = FactoryBot.create(:service, :name => "service1")
      post(api_requests_url, :params => gen_request(:create,
                                                    :options      => {
                                                      :request_type => "service_reconfigure",
                                                      :src_id       => service.id
                                                    },
                                                    :auto_approve => false))

      expected = {
        "results" => [
          a_hash_including(
            "description"    => "Service Reconfigure for: #{service.name}",
            "approval_state" => "pending_approval",
            "type"           => "ServiceReconfigureRequest",
            "requester_name" => @user.name,
            "options"        => a_hash_including("src_id" => service.id.to_s)
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    context "supported request types" do
      Api::ApiConfig.collections.requests.collection_actions.post.detect { |i| i[:name] == "create" }.identifiers.collect do |type|
        request_type = MiqRequest::REQUEST_TYPE_TO_MODEL.invert[type.klass.to_sym]
        [type.klass, request_type, type.identifier&.to_sym]
      end.each do |klass_name, request_type, identifier|
        it "#{klass_name}" do
          identifier ? api_basic_authorize(identifier) : api_basic_authorize
          klass = klass_name.safe_constantize
          expect(klass).to receive(:create_request).and_return(klass.new)
          post(api_requests_url, :params => gen_request(:create, :options => {:__request_type__ => request_type}))

          expect(response).to have_http_status(:ok)
        end
      end
    end

    it "succeed immediately with optional data and auto_approve set to true" do
      api_basic_authorize :service_reconfigure

      approver = FactoryBot.create(:user_miq_request_approver)
      service = FactoryBot.create(:service, :name => "service1")
      post(api_requests_url, :params => gen_request(:create,
                                                    :options      => {
                                                      :request_type => "service_reconfigure",
                                                      :src_id       => service.id,
                                                      :other_attr   => "other value"
                                                    },
                                                    :requester    => { "user_name" => approver.userid },
                                                    :auto_approve => true))

      expected = {
        "results" => [
          a_hash_including(
            "description"    => "Service Reconfigure for: #{service.name}",
            "approval_state" => "approved",
            "type"           => "ServiceReconfigureRequest",
            "requester_name" => approver.name,
            "options"        => a_hash_including("src_id" => service.id.to_s, "other_attr" => "other value")
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "exposes various attributes in the request resources" do
      ems = FactoryBot.create(:ems_vmware)
      vm_template = FactoryBot.create(:template_vmware, :name => "template1", :ext_management_system => ems)
      request = FactoryBot.create(:miq_provision_request,
                                   :requester => @user,
                                   :src_vm_id => vm_template.id,
                                   :options   => {:owner_email => 'tester@example.com', :src_vm_id => vm_template.id})
      FactoryBot.create(:miq_dialog,
                         :name        => "miq_provision_dialogs",
                         :dialog_type => MiqProvisionWorkflow)

      FactoryBot.create(:classification_department_with_tags)

      t = Classification.where(:description => 'Department', :parent_id => nil).includes(:tag).first
      request.add_tag(t.name, t.children.first.name)

      api_basic_authorize action_identifier(:requests, :read, :resource_actions, :get)
      get api_request_url(nil, request), :params => { :attributes => "workflow,v_allowed_tags,v_workflow_class" }

      expected_response = a_hash_including(
        "id"               => request.id.to_s,
        "workflow"         => a_hash_including("values"),
        "v_allowed_tags"   => [a_hash_including("children")],
        "v_workflow_class" => a_hash_including(
          "instance_logger" => a_hash_including("klass" => request.workflow.class.to_s))
      )

      expect(response.parsed_body).to match(expected_response)
      expect(response).to have_http_status(:ok)
    end

    it "can access attributes of its workflow" do
      ems = FactoryBot.create(:ems_vmware)
      vm_template = FactoryBot.create(:template_vmware, :name => "template1", :ext_management_system => ems)
      request = FactoryBot.create(:miq_provision_request,
                                   :requester => @user,
                                   :src_vm_id => vm_template.id,
                                   :options   => {:owner_email => 'tester@example.com', :src_vm_id => vm_template.id})
      FactoryBot.create(:miq_dialog,
                         :name        => "miq_provision_dialogs",
                         :dialog_type => MiqProvisionWorkflow)

      FactoryBot.create(:classification_department_with_tags)

      t = Classification.where(:description => 'Department', :parent_id => nil).includes(:tag).first
      request.add_tag(t.name, t.children.first.name)

      api_basic_authorize action_identifier(:requests, :read, :resource_actions, :get)
      get api_request_url(nil, request), :params => { :attributes => "workflow.values" }

      expected_response = a_hash_including(
        "id"       => request.id.to_s,
        "workflow" => a_hash_including("values")
      )

      expect(response.parsed_body).to match(expected_response)
      expect(response).to have_http_status(:ok)
    end

    it "does not throw a DelegationError exception when workflow is nil" do
      ems = FactoryBot.create(:ems_vmware)
      vm_template = FactoryBot.create(:template_vmware, :name => "template1", :ext_management_system => ems)
      request = FactoryBot.create(:service_template_provision_request,
                                   :requester   => @user,
                                   :source_id   => vm_template.id,
                                   :source_type => vm_template.class.name)

      api_basic_authorize action_identifier(:requests, :read, :resource_actions, :get)
      get api_request_url(nil, request), :params => { :attributes => "workflow,v_allowed_tags,v_workflow_class" }

      expected_response = a_hash_including(
        "id"               => request.id.to_s,
        "v_workflow_class" => {}
      )

      expect(response.parsed_body).to match(expected_response)
      expect(response.parsed_body).not_to include("workflow")
      expect(response.parsed_body).not_to include("v_allowed_tags")
      expect(response).to have_http_status(:ok)
    end
  end

  context "request update" do
    it "is forbidden for a user without appropriate role" do
      api_basic_authorize

      post(api_requests_url, :params => gen_request(:edit))

      expect(response).to have_http_status(:forbidden)
    end

    it "fails with an invalid request id" do
      api_basic_authorize collection_action_identifier(:requests, :edit)

      post(api_request_url(nil, 999_999), :params => gen_request(:edit, :options => { :some_option => "some_value" }))

      expected = {
        "error" => a_hash_including(
          "message" => /Couldn't find MiqRequest/
        )
      }
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to include(expected)
    end

    it "succeed" do
      api_basic_authorize(action_identifier(:requests, :edit))

      service = FactoryBot.create(:service, :name => "service1")
      request = ServiceReconfigureRequest.create_request({ :src_id => service.id }, @user, false)

      post(api_request_url(nil, request), :params => gen_request(:edit, :options => { :some_option => "some_value" }))

      expected = {
        "id"      => request.id.to_s,
        "options" => a_hash_including("some_option" => "some_value")
      }

      expect_single_resource_query(expected)
      expect(response).to have_http_status(:ok)
    end

    it "fails without an id" do
      api_basic_authorize(collection_action_identifier(:requests, :edit))
      service = FactoryBot.create(:service, :name => "service1")
      ServiceReconfigureRequest.create_request({:src_id => service.id}, @user, false)

      post(api_requests_url, :params => gen_request(:edit, :options => {:some_option => "some_value"}))

      expect(response.parsed_body).to include_error_with_message(/Must specify a id/)
      expect(response).to have_http_status(:bad_request)
    end
  end

  context "Requests approval" do
    let(:service1)      { FactoryBot.create(:service, :name => "service1") }
    let(:request1)      { ServiceReconfigureRequest.create_request({ :src_id => service1.id }, @user, false) }
    let(:request1_url)  { api_request_url(nil, request1) }

    let(:service2)      { FactoryBot.create(:service, :name => "service2") }
    let(:request2)      { ServiceReconfigureRequest.create_request({ :src_id => service2.id }, @user, false) }
    let(:request2_url)  { api_request_url(nil, request2) }

    it "supports approving a request" do
      api_basic_authorize collection_action_identifier(:requests, :approve)

      post(request1_url, :params => gen_request(:approve, :reason => "approval reason"))

      expected_msg = "Request #{request1.id} approved"
      expect_single_action_result(:success => true, :message => expected_msg, :href => api_request_url(nil, request1))
    end

    it "fails approving a request if the reason is missing" do
      api_basic_authorize collection_action_identifier(:requests, :approve)

      post(request1_url, :params => gen_request(:approve))

      expected_msg = /Must specify a reason for approving a request/
      expect_single_action_result(:success => false, :message => expected_msg)
    end

    it "supports denying a request" do
      api_basic_authorize collection_action_identifier(:requests, :deny)

      post(request1_url, :params => gen_request(:deny, :reason => "denial reason"))

      expected_msg = "Request #{request1.id} denied"
      expect_single_action_result(:success => true, :message => expected_msg, :href => api_request_url(nil, request1))
    end

    it "fails denying a request if the reason is missing" do
      api_basic_authorize collection_action_identifier(:requests, :deny)

      post(request1_url, :params => gen_request(:deny))

      expected_msg = /Must specify a reason for denying a request/
      expect_single_action_result(:success => false, :message => expected_msg)
    end

    it "supports approving multiple requests" do
      api_basic_authorize collection_action_identifier(:requests, :approve)

      post(api_requests_url, :params => gen_request(:approve, [{:href => request1_url, :reason => "approval reason"},
                                                               {:href => request2_url, :reason => "approval reason"}]))

      expected = {
        "results" => a_collection_containing_exactly(
          {
            "message" => a_string_matching(/Request #{request1.id} approved/i),
            "success" => true,
            "href"    => api_request_url(nil, request1)
          },
          {
            "message" => a_string_matching(/Request #{request2.id} approved/i),
            "success" => true,
            "href"    => api_request_url(nil, request2)
          }
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports denying multiple requests" do
      api_basic_authorize collection_action_identifier(:requests, :approve)

      post(api_requests_url, :params => gen_request(:deny, [{:href => request1_url, :reason => "denial reason"},
                                                            {:href => request2_url, :reason => "denial reason"}]))

      expected = {
        "results" => a_collection_containing_exactly(
          {
            "message" => a_string_matching(/Request #{request1.id} denied/i),
            "success" => true,
            "href"    => api_request_url(nil, request1)
          },
          {
            "message" => a_string_matching(/Request #{request2.id} denied/i),
            "success" => true,
            "href"    => api_request_url(nil, request2)
          }
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  context "resource hrefs" do
    it "returns the requests href reference for objects of different subclasses" do
      provision_request = FactoryBot.create(:service_template_provision_request, :requester => @user)
      automation_request = FactoryBot.create(:automation_request, :requester => @user)
      api_basic_authorize collection_action_identifier(:requests, :read, :get)

      get api_requests_url, :params => { :expand => :resources }

      expected = [
        a_hash_including('href' => a_string_including(api_request_url(nil, provision_request))),
        a_hash_including('href' => a_string_including(api_request_url(nil, automation_request)))
      ]
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['resources']).to match_array(expected)
    end
  end

  context 'href_slug' do
    it 'returns the correct slug for a request' do
      api_basic_authorize action_identifier(:requests, :read, :resource_actions, :get)
      request = FactoryBot.create(:automation_request, :requester => @user)

      get(api_request_url(nil, request), :params => { :attributes => 'href_slug' })

      expect(response.parsed_body['href_slug']).to eq("requests/#{request.id}")
    end
  end

  context 'Tasks subcollection' do
    let(:request) do
      FactoryBot.create(:service_template_provision_request,
                         :requester   => @user,
                         :source_id   => template.id,
                         :source_type => template.class.name)
    end
    let(:task) { FactoryBot.create(:miq_request_task, :miq_request_id => request.id) }
    let(:params) { gen_request(:edit, :options => { :a => "1" }) }

    it 'does not allow direct edit of task' do
      api_basic_authorize

      post(api_request_task_url(nil, task), :params => params)

      expect(response).to have_http_status(:bad_request)
    end

    it 'allows access to underlying task' do
      api_basic_authorize collection_action_identifier(:requests, :read, :get)

      get("#{api_request_url(nil, request)}/request_tasks/#{task.id}")

      expect(response).to have_http_status(:ok)
    end

    it 'allows edit of task as a subcollection of request' do
      tasks_url = "#{api_request_url(nil, request)}/request_tasks/#{task.id}"
      api_basic_authorize subcollection_action_identifier(:requests, :request_tasks, :edit)
      post(tasks_url, :params => params)

      expect(response).to have_http_status(:ok)
      expect(task.reload.options.keys).to all(be_kind_of(Symbol))
    end

    context "SubResource#cancel" do
      let(:resource_1_response) { {"success" => false, "message" => "Cancel operation is not supported for MiqRequestTask"} }
      let(:resource_2_response) { {"success" => false, "message" => "Cancel operation is not supported for MiqRequestTask"} }
      include_context "SubResource#cancel", [:request, :request_task], :service_template_provision_request, :miq_request_task
    end
  end

  context "Resource#cancel" do
    let(:resource_1_response) { {"success" => false, "message" => "Cancel operation is not supported for VmMigrateRequest"} }
    let(:resource_2_response) { {"success" => false, "message" => "Cancel operation is not supported for VmMigrateRequest"} }
    include_context "Resource#cancel", "request", :vm_migrate_request
  end
end
