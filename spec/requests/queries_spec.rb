#
# REST API Request Tests - Queries
#
describe "Queries API" do
  let(:zone)       { FactoryGirl.create(:zone, :name => "api_zone") }
  let(:ems)        { FactoryGirl.create(:ems_vmware, :zone => zone) }
  let(:host)       { FactoryGirl.create(:host) }

  let(:vm1)        { FactoryGirl.create(:vm_vmware, :host => host, :ems_id => ems.id, :raw_power_state => "poweredOn") }
  let(:vm1_url)    { api_vm_url(nil, vm1) }

  let(:vm_href_pattern) { %r{^http://.*/api/vms/[0-9r]+$} }

  def create_vms(count)
    count.times { FactoryGirl.create(:vm_vmware) }
  end

  describe "Query collections" do
    it "returns resource lists with only hrefs" do
      api_basic_authorize collection_action_identifier(:vms, :read, :get)
      create_vms(3)

      get api_vms_url

      expect_query_result(:vms, 3, 3)
      expect(response.parsed_body).to include("resources" => all(match("href" => a_string_matching(vm_href_pattern))))
    end

    it "returns seperate ids and href when expanded" do
      api_basic_authorize collection_action_identifier(:vms, :read, :get)
      create_vms(3)

      get api_vms_url, :expand => "resources"

      expect_query_result(:vms, 3, 3)
      expected = {
        "resources" => all(a_hash_including("href" => a_string_matching(vm_href_pattern),
                                            "id"   => a_kind_of(String),
                                            "guid" => anything))
      }
      expect(response.parsed_body).to include(expected)
    end

    it "always return ids and href when asking for specific attributes" do
      api_basic_authorize collection_action_identifier(:vms, :read, :get)
      vm1   # create resource

      get api_vms_url, :expand => "resources", :attributes => "guid"

      expect_query_result(:vms, 1, 1)
      expect_result_resources_to_match_hash([{"id" => vm1.compressed_id, "href" => api_vm_url(nil, vm1.compressed_id), "guid" => vm1.guid}])
    end
  end

  describe "Query resource" do
    it "returns both id and href" do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
      vm1   # create resource

      get vm1_url

      expect_single_resource_query("id" => vm1.compressed_id, "href" => api_vm_url(nil, vm1.compressed_id), "guid" => vm1.guid)
    end

    it 'supports compressed ids' do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)

      get api_vm_url(nil, vm1.compressed_id)

      expect_single_resource_query("id" => vm1.compressed_id, "href" => api_vm_url(nil, vm1.compressed_id), "guid" => vm1.guid)
    end

    it 'returns 404 on url with trailing garbage' do
      api_basic_authorize action_identifier(:vms, :read, :resource_actions, :get)
      vm1   # create resource

      get vm1_url + 'garbage'

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Query subcollections" do
    let(:acct1) { FactoryGirl.create(:account, :vm_or_template_id => vm1.id, :name => "John") }
    let(:acct2) { FactoryGirl.create(:account, :vm_or_template_id => vm1.id, :name => "Jane") }
    let(:vm1_accounts_url) { api_vm_accounts_url(nil, vm1) }
    let(:acct1_url)        { api_vm_account_url(nil, vm1, acct1) }
    let(:acct2_url)        { api_vm_account_url(nil, vm1, acct2) }
    let(:vm1_accounts_url_list) { [acct1_url, acct2_url] }

    it "returns just href when not expanded" do
      api_basic_authorize
      # create resources
      acct1
      acct2

      get vm1_accounts_url

      expect_query_result(:accounts, 2)
      expect_result_resources_to_include_hrefs("resources",
                                               [api_vm_account_url(nil, vm1.compressed_id, acct1.compressed_id),
                                                api_vm_account_url(nil, vm1.compressed_id, acct2.compressed_id)])
    end

    it "includes both id and href when getting a single resource" do
      api_basic_authorize

      get acct1_url

      expect_single_resource_query(
        "id"   => acct1.compressed_id,
        "href" => api_vm_account_url(nil, vm1.compressed_id, acct1.compressed_id),
        "name" => acct1.name
      )
    end

    it "includes both id and href when expanded" do
      api_basic_authorize
      # create resources
      acct1
      acct2

      get vm1_accounts_url, :expand => "resources"

      expect_query_result(:accounts, 2)
      expect_result_resources_to_include_keys("resources", %w(id href))
      expect_result_resources_to_include_hrefs("resources",
                                               [api_vm_account_url(nil, vm1.compressed_id, acct1.compressed_id),
                                                api_vm_account_url(nil, vm1.compressed_id, acct2.compressed_id)])
      expect_result_resources_to_include_data("resources", "id" => [acct1.compressed_id, acct2.compressed_id])
    end

    it 'supports compressed ids' do
      api_basic_authorize

      get(api_vm_account_url(nil, vm1.compressed_id, acct1))

      expect_single_resource_query(
        "id"   => acct1.compressed_id,
        "href" => api_vm_account_url(nil, vm1.compressed_id, acct1.compressed_id),
        "name" => acct1.name
      )
    end

    it 'returns 404 on url with trailing garbage' do
      api_basic_authorize

      get acct1_url + 'garbage'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Querying encrypted attributes" do
    it "hides them from database records" do
      api_basic_authorize action_identifier(:providers, :read, :resource_actions, :get)

      credentials = {:userid => "admin", :password => "super_password"}

      provider = FactoryGirl.create(:ext_management_system, :name => "sample", :hostname => "sample.com")
      provider.update_authentication(:default => credentials)

      get(api_provider_url(nil, provider), :attributes => "authentications")

      expect(response).to have_http_status(:ok)
      expect_result_to_match_hash(response.parsed_body, "name" => "sample")
      expect_result_to_have_keys(%w(authentications))
      authentication = response.parsed_body["authentications"].first
      expect(authentication["userid"]).to eq("admin")
      expect(authentication.key?("password")).to be_falsey
    end

    it "hides them from provisioning hashes" do
      api_basic_authorize action_identifier(:provision_requests, :read, :resource_actions, :get)

      password_field = ::MiqRequestWorkflow.all_encrypted_options_fields.last.to_s
      options = {:attrs => {:userid => "admin", password_field.to_sym => "super_password"}}

      template = FactoryGirl.create(:template_vmware, :name => "template1")
      request  = FactoryGirl.create(:miq_provision_request,
                                    :requester   => @user,
                                    :description => "sample provision",
                                    :src_vm_id   => template.id,
                                    :options     => options)

      get api_provision_request_url(nil, request)

      expect(response).to have_http_status(:ok)
      expect_result_to_match_hash(response.parsed_body, "description" => "sample provision")
      provision_attrs = response.parsed_body.fetch_path("options", "attrs")
      expect(provision_attrs).to_not be_nil
      expect(provision_attrs["userid"]).to eq("admin")
      expect(provision_attrs.key?(password_field)).to be_falsey
    end
  end
end
