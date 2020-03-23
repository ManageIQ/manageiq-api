RSpec.describe "hosts API" do
  describe "editing a host's password" do
    context "with an appropriate role" do
      it "can edit the password on a host" do
        host = FactoryBot.create(:host_with_authentication)
        api_basic_authorize action_identifier(:hosts, :edit)
        options = {:credentials => {:authtype => "default", :password => "abc123"}}

        expect do
          post api_host_url(nil, host), :params => gen_request(:edit, options)
        end.to change { host.reload.authentication_password(:default) }.to("abc123")
        expect(response).to have_http_status(:ok)
      end

      it "will update the default authentication if no type is given" do
        host = FactoryBot.create(:host_with_authentication)
        api_basic_authorize action_identifier(:hosts, :edit)
        options = {:credentials => {:password => "abc123"}}

        expect do
          post api_host_url(nil, host), :params => gen_request(:edit, options)
        end.to change { host.reload.authentication_password(:default) }.to("abc123")
        expect(response).to have_http_status(:ok)
      end

      it "can edit the password on a host without creating duplicate keys" do
        host = FactoryBot.create(:host)
        api_basic_authorize action_identifier(:hosts, :edit)
        options = { :credentials => { 'userid' => "I'm", 'password' => 'abc123' } }

        expect do
          post api_host_url(nil, host), :params => gen_request(:edit, options)
        end.to change { host.reload.authentication_password(:default) }.to('abc123')
        expect(response).to have_http_status(:ok)
      end

      it "sending non-credentials attributes will result in a bad request error" do
        host = FactoryBot.create(:host_with_authentication)
        api_basic_authorize action_identifier(:hosts, :edit)
        options = {:name => "new name"}

        expect do
          post api_host_url(nil, host), :params => gen_request(:edit, options)
        end.not_to change { host.reload.name }
        expect(response).to have_http_status(:bad_request)
      end

      it "can update passwords on multiple hosts by href" do
        host1 = FactoryBot.create(:host_with_authentication)
        host2 = FactoryBot.create(:host_with_authentication)
        api_basic_authorize action_identifier(:hosts, :edit)
        options = [
          {:href => api_host_url(nil, host1), :credentials => {:password => "abc123"}},
          {:href => api_host_url(nil, host2), :credentials => {:password => "def456"}}
        ]

        post api_hosts_url, :params => gen_request(:edit, options)
        expect(response).to have_http_status(:ok)
        expect(host1.reload.authentication_password(:default)).to eq("abc123")
        expect(host2.reload.authentication_password(:default)).to eq("def456")
      end

      it "can update passwords on multiple hosts by id" do
        host1 = FactoryBot.create(:host_with_authentication)
        host2 = FactoryBot.create(:host_with_authentication)
        api_basic_authorize action_identifier(:hosts, :edit)
        options = [
          {:id => host1.id, :credentials => {:password => "abc123"}},
          {:id => host2.id, :credentials => {:password => "def456"}}
        ]

        post api_hosts_url, :params => gen_request(:edit, options)
        expect(response).to have_http_status(:ok)
        expect(host1.reload.authentication_password(:default)).to eq("abc123")
        expect(host2.reload.authentication_password(:default)).to eq("def456")
      end
    end

    context "without an appropriate role" do
      it "cannot edit the password on a host" do
        host = FactoryBot.create(:host_with_authentication)
        api_basic_authorize
        options = {:credentials => {:authtype => "default", :password => "abc123"}}

        expect do
          post api_host_url(nil, host), :params => gen_request(:edit, options)
        end.not_to change { host.reload.authentication_password(:default) }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'Lans subcollection' do
      let(:lan) { FactoryBot.create(:lan) }
      let(:switch) { FactoryBot.create(:switch, :lans => [lan]) }
      let(:host) { FactoryBot.create(:host, :switches => [switch]) }

      context 'GET /api/hosts/:id/lans' do
        it 'returns the lans with an appropriate role' do
          api_basic_authorize(collection_action_identifier(:hosts, :read, :get))

          expected = {
            'resources' => [{'href' => api_host_lan_url(nil, host, lan)}]
          }
          get(api_host_lans_url(nil, host))

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(expected)
        end

        it 'does not return the lans without an appropriate role' do
          api_basic_authorize

          get(api_host_lans_url(nil, host))

          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'GET /api/hosts/:id/lans/:s_id' do
        it 'returns the lan with an appropriate role' do
          api_basic_authorize action_identifier(:hosts, :read, :resource_actions, :get)

          get(api_host_lan_url(nil, host, lan))

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include('id' => lan.id.to_s)
        end

        it 'does not return the lans without an appropriate role' do
          api_basic_authorize

          get(api_host_lan_url(nil, host, lan))

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  context "CustomAttributes subcollection" do
    let(:host) { FactoryBot.create(:host_with_authentication) }

    let(:ca1) { FactoryBot.create(:custom_attribute, :name => "name1", :value => "value1") }
    let(:ca2) { FactoryBot.create(:custom_attribute, :name => "name2", :value => "value2") }
    let(:ca1_url)        { api_host_custom_attribute_url(nil, host, ca1) }
    let(:ca2_url)        { api_host_custom_attribute_url(nil, host, ca2) }

    it "getting custom_attributes from a host with no custom_attributes" do
      api_basic_authorize

      get(api_host_custom_attributes_url(nil, host))

      expect_empty_query_result(:custom_attributes)
    end

    it "getting custom_attributes from a host" do
      api_basic_authorize
      host.custom_attributes = [ca1, ca2]

      get api_host_custom_attributes_url(nil, host)

      expect_query_result(:custom_attributes, 2)
      expect_result_resources_to_include_hrefs("resources",
                                               [api_host_custom_attribute_url(nil, host, ca1),
                                                api_host_custom_attribute_url(nil, host, ca2)])
    end

    it "getting custom_attributes from a host in expanded form" do
      api_basic_authorize
      host.custom_attributes = [ca1, ca2]

      get api_host_custom_attributes_url(nil, host), :params => {:expand => "resources"}

      expect_query_result(:custom_attributes, 2)
      expect_result_resources_to_include_data("resources", "name" => %w[name1 name2])
    end

    it "getting custom_attributes from a host using expand" do
      api_basic_authorize action_identifier(:hosts, :read, :resource_actions, :get)
      host.custom_attributes = [ca1, ca2]

      get api_host_url(nil, host), :params => {:expand => "custom_attributes"}

      expect_single_resource_query("guid" => host.guid)
      expect_result_resources_to_include_data("custom_attributes", "name" => %w[name1 name2])
    end

    it "delete a custom_attribute without appropriate role" do
      api_basic_authorize
      host.custom_attributes = [ca1]

      post(api_host_custom_attributes_url(nil, host), :params => gen_request(:delete, nil, host_url))

      expect(response).to have_http_status(:forbidden)
    end

    it "delete a custom_attribute from a host via the delete action" do
      api_basic_authorize action_identifier(:hosts, :edit)
      host.custom_attributes = [ca1]

      post(api_host_custom_attributes_url(nil, host), :params => gen_request(:delete, nil, ca1_url))

      expect(response).to have_http_status(:ok)
      expect(host.reload.custom_attributes).to be_empty
    end

    it "add custom attribute to a hosts without a name" do
      api_basic_authorize action_identifier(:hosts, :edit)

      post(api_host_custom_attributes_url(nil, host), :params => gen_request(:add, "value" => "value1"))

      expect_bad_request("Must specify a name")
    end

    it "add custom attributes to a host" do
      api_basic_authorize action_identifier(:hosts, :edit)

      params = gen_request(:add, [{"name" => "name1", "value" => "value1"}, {"name" => "name2", "value" => "value2"}])
      post(api_host_custom_attributes_url(nil, host), :params => params)

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_data("results", "name" => %w[name1 name2])
      expect(host.custom_attributes.size).to eq(2)
      expect(host.custom_attributes.pluck(:value).sort).to eq(%w[value1 value2])
    end

    it "edit a custom attribute by name" do
      api_basic_authorize action_identifier(:hosts, :edit)
      host.custom_attributes = [ca1]

      post(api_host_custom_attributes_url(nil, host), :params => gen_request(:edit, "name" => "name1", "value" => "value one"))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_data("results", "value" => ["value one"])
      expect(host.reload.custom_attributes.first.value).to eq("value one")
    end

    it "edit a custom attribute by href" do
      api_basic_authorize action_identifier(:hosts, :edit)
      host.custom_attributes = [ca1]

      post(api_host_custom_attributes_url(nil, host), :params => gen_request(:edit, "href" => ca1_url, "value" => "new value1"))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_data("results", "value" => ["new value1"])
      expect(host.reload.custom_attributes.first.value).to eq("new value1")
    end

    it "edit multiple custom attributes" do
      api_basic_authorize action_identifier(:hosts, :edit)
      host.custom_attributes = [ca1, ca2]

      params = gen_request(:edit, [{"name" => "name1", "value" => "new value1"}, {"name" => "name2", "value" => "new value2"}])
      post(api_host_custom_attributes_url(nil, host), :params => params)

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_data("results", "value" => ["new value1", "new value2"])
      expect(host.reload.custom_attributes.pluck(:value).sort).to eq(["new value1", "new value2"])
    end
  end
end
