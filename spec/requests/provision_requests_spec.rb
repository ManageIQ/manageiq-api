#
# Rest API Request Tests - Provision Requests specs
#
# - Create single provision request    /api/provision_requests    normal POST
# - Create single provision request    /api/provision_requests    action "create"
# - Create multiple provision requests /api/provision_requests    action "create"
#
describe "Provision Requests API" do
  context "AWS advanced provision requests" do
    let!(:aws_dialog) do
      path = Rails.root.join("product", "dialogs", "miq_dialogs", "miq_provision_amazon_dialogs_template.yaml")
      content = YAML.load_file(path)[:content]
      dialog = FactoryGirl.create(:miq_dialog, :name => "miq_provision_amazon_dialogs_template",
                                  :dialog_type => "MiqProvisionWorkflow", :content => content)
      allow_any_instance_of(MiqRequestWorkflow).to receive(:dialog_name_from_automate).and_return(dialog.name)
    end
    let(:ems) { FactoryGirl.create(:ems_amazon_with_authentication) }
    let(:template) do
      FactoryGirl.create(:template_amazon, :name => "template1", :ext_management_system => ems)
    end
    let(:flavor) do
      FactoryGirl.create(:flavor_amazon, :ems_id => ems.id, :name => 't2.small', :cloud_subnet_required => true)
    end
    let(:az)             { FactoryGirl.create(:availability_zone_amazon, :ems_id => ems.id) }
    let(:cloud_network1) do
      FactoryGirl.create(:cloud_network_amazon,
                         :ext_management_system => ems.network_manager,
                         :enabled               => true)
    end
    let(:cloud_subnet1) do
      FactoryGirl.create(:cloud_subnet,
                         :ext_management_system => ems.network_manager,
                         :cloud_network         => cloud_network1,
                         :availability_zone     => az)
    end
    let(:security_group1) do
      FactoryGirl.create(:security_group_amazon,
                         :name                  => "sgn_1",
                         :ext_management_system => ems.network_manager,
                         :cloud_network         => cloud_network1)
    end
    let(:floating_ip1) do
      FactoryGirl.create(:floating_ip_amazon,
                         :cloud_network_only    => true,
                         :ext_management_system => ems.network_manager,
                         :cloud_network         => cloud_network1)
    end

    let(:provreq_body) do
      {
        "template_fields" => {"guid" => template.guid},
        "requester"       => {
          "owner_first_name" => "John",
          "owner_last_name"  => "Doe",
          "owner_email"      => "user@example.com"
        }
      }
    end

    let(:expected_provreq_attributes) { %w(id options) }

    let(:expected_provreq_hash) do
      {
        "userid"         => api_config(:user),
        "requester_name" => api_config(:user_name),
        "approval_state" => "pending_approval",
        "type"           => "MiqProvisionRequest",
        "request_type"   => "template",
        "message"        => /Provisioning/i,
        "status"         => "Ok"
      }
    end

    it "supports manual placement" do
      api_basic_authorize collection_action_identifier(:provision_requests, :create)

      body = provreq_body.merge(
        "vm_fields" => {
          "vm_name"                     => "api_test_aws",
          "instance_type"               => flavor.id,
          "placement_auto"              => false,
          "placement_availability_zone" => az.id,
          "cloud_network"               => cloud_network1.id,
          "cloud_subnet"                => cloud_subnet1.id,
          "security_groups"             => security_group1.id,
          "floating_ip_address"         => floating_ip1.id
        }
      )

      run_post(provision_requests_url, body)

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_provreq_attributes)
      expect_results_to_match_hash("results", [expected_provreq_hash])

      expect(response.parsed_body["results"].first).to a_hash_including(
        "options" => a_hash_including(
          "placement_auto"              => [false, 0],
          "placement_availability_zone" => [az.id, az.name],
          "cloud_network"               => [cloud_network1.id, cloud_network1.name],
          "cloud_subnet"                => [cloud_subnet1.id, anything],
          "security_groups"             => [security_group1.id],
          "floating_ip_address"         => [floating_ip1.id, floating_ip1.name]
        )
      )

      task_id = ApplicationRecord.uncompress_id(response.parsed_body["results"].first["id"])
      expect(MiqProvisionRequest.exists?(task_id)).to be_truthy
    end

    it "does not process manual placement data if placement_auto is not set" do
      api_basic_authorize collection_action_identifier(:provision_requests, :create)

      body = provreq_body.merge(
        "vm_fields" => {
          "vm_name"                     => "api_test_aws",
          "instance_type"               => flavor.id,
          "placement_availability_zone" => az.id
        }
      )

      run_post(provision_requests_url, body)

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_provreq_attributes)
      expect_results_to_match_hash("results", [expected_provreq_hash])

      expect(response.parsed_body["results"].first).to a_hash_including(
        "options" => a_hash_including(
          "placement_auto"              => [true, 1],
          "placement_availability_zone" => [nil, nil]
        )
      )

      task_id = ApplicationRecord.uncompress_id(response.parsed_body["results"].first["id"])
      expect(MiqProvisionRequest.exists?(task_id)).to be_truthy
    end

    it "does not process manual placement data if placement_auto is set to true" do
      api_basic_authorize collection_action_identifier(:provision_requests, :create)

      body = provreq_body.merge(
        "vm_fields" => {
          "vm_name"                     => "api_test_aws",
          "instance_type"               => flavor.id,
          "placement_auto"              => true,
          "placement_availability_zone" => az.id
        }
      )

      run_post(provision_requests_url, body)

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_provreq_attributes)
      expect_results_to_match_hash("results", [expected_provreq_hash])

      expect(response.parsed_body["results"].first).to a_hash_including(
        "options" => a_hash_including(
          "placement_auto"              => [true, 1],
          "placement_availability_zone" => [nil, nil]
        )
      )

      task_id = ApplicationRecord.uncompress_id(response.parsed_body["results"].first["id"])
      expect(MiqProvisionRequest.exists?(task_id)).to be_truthy
    end
  end

  let(:zone)       { FactoryGirl.create(:zone, :name => "api_zone") }
  let(:ems)        { FactoryGirl.create(:ems_vmware, :zone => zone) }
  let(:host)       { FactoryGirl.create(:host, :ext_management_system => ems) }
  let(:dialog)     { FactoryGirl.create(:miq_dialog_provision) }

  describe "Provision Requests" do
    let(:hardware) { FactoryGirl.create(:hardware, :memory_mb => 1024) }
    let(:template) do
      FactoryGirl.create(:template_vmware,
                         :name                  => "template1",
                         :host                  => host,
                         :ext_management_system => ems,
                         :hardware              => hardware)
    end

    let(:single_provision_request) do
      {
        "template_fields" => {"guid" => template.guid},
        "vm_fields"       => {"number_of_cpus" => 1, "vm_name" => "api_test"},
        "requester"       => {"user_name" => api_config(:user)}
      }
    end

    let(:expected_attributes) { %w(id options) }
    let(:expected_hash) do
      {
        "userid"         => api_config(:user),
        "requester_name" => api_config(:user_name),
        "approval_state" => "pending_approval",
        "type"           => "MiqProvisionRequest",
        "request_type"   => "template",
        "message"        => /Provisioning/i,
        "status"         => "Ok"
      }
    end

    it "filters the list of provision requests by requester" do
      other_user = FactoryGirl.create(:user)
      _provision_request1 = FactoryGirl.create(:miq_provision_request, :requester => other_user)
      provision_request2 = FactoryGirl.create(:miq_provision_request, :requester => @user)
      api_basic_authorize collection_action_identifier(:provision_requests, :read, :get)

      run_get provision_requests_url

      expected = {
        "count"     => 2,
        "subcount"  => 1,
        "resources" => a_collection_containing_exactly(
          "href" => a_string_matching(provision_requests_url(provision_request2.compressed_id)),
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "lists all the provision requests if you are admin" do
      @group.miq_user_role = @role = FactoryGirl.create(:miq_user_role, :role => "administrator")
      other_user = FactoryGirl.create(:user)
      provision_request1 = FactoryGirl.create(:miq_provision_request, :requester => other_user)
      provision_request2 = FactoryGirl.create(:miq_provision_request, :requester => @user)
      api_basic_authorize collection_action_identifier(:provision_requests, :read, :get)

      run_get provision_requests_url

      expected = {
        "count"     => 2,
        "subcount"  => 2,
        "resources" => a_collection_containing_exactly(
          {"href" => a_string_matching(provision_requests_url(provision_request1.compressed_id))},
          {"href" => a_string_matching(provision_requests_url(provision_request2.compressed_id))},
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "restricts access to provision requests to requester" do
      other_user = FactoryGirl.create(:user)
      provision_request = FactoryGirl.create(:miq_provision_request, :requester => other_user)
      api_basic_authorize action_identifier(:provision_requests, :read, :resource_actions, :get)

      run_get provision_requests_url(provision_request.id)

      expect(response).to have_http_status(:not_found)
    end

    it "an admin can see another user's request" do
      @group.miq_user_role = @role = FactoryGirl.create(:miq_user_role, :role => "administrator")
      other_user = FactoryGirl.create(:user)
      provision_request = FactoryGirl.create(:miq_provision_request, :requester => other_user)
      api_basic_authorize action_identifier(:provision_requests, :read, :resource_actions, :get)

      run_get provision_requests_url(provision_request.id)

      expected = {
        "id"   => provision_request.compressed_id,
        "href" => a_string_matching(provision_requests_url(provision_request.compressed_id))
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "rejects requests without appropriate role" do
      api_basic_authorize

      run_post(provision_requests_url, single_provision_request)

      expect(response).to have_http_status(:forbidden)
    end

    it "supports single request with normal post" do
      api_basic_authorize collection_action_identifier(:provision_requests, :create)

      dialog  # Create the Provisioning dialog
      run_post(provision_requests_url, single_provision_request)

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)
      expect_results_to_match_hash("results", [expected_hash])

      task_id = ApplicationRecord.uncompress_id(response.parsed_body["results"].first["id"])
      expect(MiqProvisionRequest.exists?(task_id)).to be_truthy
    end

    it "supports single request with create action" do
      api_basic_authorize collection_action_identifier(:provision_requests, :create)

      dialog  # Create the Provisioning dialog
      run_post(provision_requests_url, gen_request(:create, single_provision_request))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)
      expect_results_to_match_hash("results", [expected_hash])

      task_id = ApplicationRecord.uncompress_id(response.parsed_body["results"].first["id"])
      expect(MiqProvisionRequest.exists?(task_id)).to be_truthy
    end

    it "supports multiple requests" do
      api_basic_authorize collection_action_identifier(:provision_requests, :create)

      dialog  # Create the Provisioning dialog
      run_post(provision_requests_url, gen_request(:create, [single_provision_request, single_provision_request]))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)
      expect_results_to_match_hash("results", [expected_hash, expected_hash])

      task_id1, task_id2 = response.parsed_body["results"].collect { |r| ApplicationRecord.uncompress_id(r["id"]) }
      expect(MiqProvisionRequest.exists?(task_id1)).to be_truthy
      expect(MiqProvisionRequest.exists?(task_id2)).to be_truthy
    end

    describe "provision request update" do
      it 'forbids provision request update without an appropriate role' do
        provision_request = FactoryGirl.create(:miq_provision_request, :requester => @user, :options => {:foo => "bar"})
        api_basic_authorize

        run_post(provision_requests_url(provision_request.id), :action => "edit", :options => {:baz => "qux"})

        expect(response).to have_http_status(:forbidden)
      end

      it 'updates a single provision request' do
        provision_request = FactoryGirl.create(:miq_provision_request, :requester => @user, :options => {:foo => "bar"})
        api_basic_authorize(action_identifier(:provision_requests, :edit))

        run_post(provision_requests_url(provision_request.id), :action => "edit", :options => {:baz => "qux"})

        expected = {
          "id"      => provision_request.compressed_id,
          "options" => a_hash_including("foo" => "bar", "baz" => "qux")
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      it 'updates multiple provision requests' do
        provision_request, provision_request2 = FactoryGirl.create_list(:miq_provision_request,
                                                                        2,
                                                                        :requester => @user,
                                                                        :options   => {:foo => "bar"})
        api_basic_authorize collection_action_identifier(:service_requests, :edit)

        run_post(
          provision_requests_url,
          :action    => "edit",
          :resources => [
            {:id => provision_request.id, :options => {:baz => "qux"}},
            {:id => provision_request2.id, :options => {:quux => "quuz"}}
          ]
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
  end

  context "Provision requests approval" do
    let(:user)          { FactoryGirl.create(:user) }
    let(:template)      { FactoryGirl.create(:template_cloud) }
    let(:provreqbody)   { {:requester => user, :source_type => 'VmOrTemplate', :source_id => template.id} }
    let(:provreq1)      { FactoryGirl.create(:miq_provision_request, provreqbody) }
    let(:provreq2)      { FactoryGirl.create(:miq_provision_request, provreqbody) }
    let(:provreq1_url)  { provision_requests_url(provreq1.id) }
    let(:provreq2_url)  { provision_requests_url(provreq2.id) }

    before do
      @group.miq_user_role = @role = FactoryGirl.create(:miq_user_role, :role => "administrator")
    end

    it "supports approving a request" do
      api_basic_authorize collection_action_identifier(:provision_requests, :approve)

      run_post(provreq1_url, gen_request(:approve))

      expected_msg = "Provision request #{provreq1.id} approved"
      expect_single_action_result(:success => true, :message => expected_msg, :href => provision_requests_url(provreq1.compressed_id))
    end

    it "supports denying a request" do
      api_basic_authorize collection_action_identifier(:provision_requests, :approve)

      run_post(provreq2_url, gen_request(:deny))

      expected_msg = "Provision request #{provreq2.id} denied"
      expect_single_action_result(:success => true, :message => expected_msg, :href => provision_requests_url(provreq2.compressed_id))
    end

    it "supports approving multiple requests" do
      api_basic_authorize collection_action_identifier(:provision_requests, :approve)

      run_post(provision_requests_url, gen_request(:approve, [{"href" => provreq1_url}, {"href" => provreq2_url}]))

      expected = {
        "results" => a_collection_containing_exactly(
          {
            "message" => a_string_matching(/Provision request #{provreq1.id} approved/i),
            "success" => true,
            "href"    => a_string_matching(provision_requests_url(provreq1.compressed_id))
          },
          {
            "message" => a_string_matching(/Provision request #{provreq2.id} approved/i),
            "success" => true,
            "href"    => a_string_matching(provision_requests_url(provreq2.compressed_id))
          }
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "supports denying multiple requests" do
      api_basic_authorize collection_action_identifier(:provision_requests, :approve)

      run_post(provision_requests_url, gen_request(:deny, [{"href" => provreq1_url}, {"href" => provreq2_url}]))

      expected = {
        "results" => a_collection_containing_exactly(
          {
            "message" => a_string_matching(/Provision request #{provreq1.id} denied/i),
            "success" => true,
            "href"    => a_string_matching(provision_requests_url(provreq1.compressed_id))
          },
          {
            "message" => a_string_matching(/Provision request #{provreq2.id} denied/i),
            "success" => true,
            "href"    => a_string_matching(provision_requests_url(provreq2.compressed_id))
          }
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  context 'Tasks subcollection' do
    let(:provision_request) { FactoryGirl.create(:miq_provision_request) }

    it 'redirects to request_tasks subcollection' do
      FactoryGirl.create(:miq_request_task, :miq_request_id => provision_request.id)
      api_basic_authorize collection_action_identifier(:service_requests, :read, :get)

      run_get("#{provision_requests_url(provision_request.id)}/tasks")

      expect(response).to have_http_status(:moved_permanently)
      expect(response.redirect_url).to include("#{provision_requests_url(provision_request.id)}/request_tasks")
    end

    it 'redirects to request_tasks subresources' do
      task = FactoryGirl.create(:miq_request_task, :miq_request_id => provision_request.id)
      api_basic_authorize action_identifier(:services, :read, :resource_actions, :get)

      run_get("#{provision_requests_url(provision_request.id)}/tasks/#{task.id}")

      expect(response).to have_http_status(:moved_permanently)
      expect(response.redirect_url).to include("#{provision_requests_url(provision_request.id)}/request_tasks/#{task.id}")
    end
  end
end
