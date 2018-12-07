describe "ConversionHosts API" do
  context "collections" do
    it 'lists all conversion hosts with an appropriate role' do
      conversion_host = FactoryGirl.create(:conversion_host)
      api_basic_authorize(collection_action_identifier(:conversion_hosts, :read, :get))
      get(api_conversion_hosts_url)

      expected = {
        'count'     => 1,
        'name'      => 'conversion_hosts',
        'resources' => [
          hash_including('href' => api_conversion_host_url(nil, conversion_host))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "resources" do
    it 'will show a conversion host with an appropriate role' do
      conversion_host = FactoryGirl.create(:conversion_host)
      api_basic_authorize(action_identifier(:conversion_hosts, :read, :resource_actions, :get))

      get(api_conversion_host_url(nil, conversion_host))

      expect(response.parsed_body).to include('href' => api_conversion_host_url(nil, conversion_host))
      expect(response).to have_http_status(:ok)
    end
  end

  context "access" do
    it "forbids access to conversion hosts without an appropriate role" do
      api_basic_authorize
      get(api_conversion_hosts_url)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids access to a conversion host resource without an appropriate role" do
      api_basic_authorize
      conversion_host = FactoryGirl.create(:conversion_host)
      get(api_conversion_host_url(nil, conversion_host))

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "create" do
    let(:vm) { FactoryGirl.create(:vm) }
    let(:host) { FactoryGirl.create(:host) }

    let(:sample_conversion_host_from_vm) do
      {
        :name          => "test_conversion_host_from_vm",
        :resource_type => vm.class.name,
        :resource_id   => vm.id,
        :version       => "1.0"
      }
    end

    let(:sample_conversion_host_from_host) do
      {
        :name          => "test_conversion_host_from_host",
        :resource_type => host.class.name,
        :resource_id   => host.id,
        :version       => "1.0"
      }
    end

    let(:expected_attributes) { %w(id name resource_type resource_id version) }

    it "supports single conversion host creation" do
      api_basic_authorize(collection_action_identifier(:conversion_hosts, :create))

      post(api_conversion_hosts_url, :params => sample_conversion_host_from_vm)

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)

      conversion_host_id = response.parsed_body["results"].first["id"]

      expect(ConversionHost.find_by(:resource_id => vm.id).id).to eql(conversion_host_id.to_i)
    end

    it "supports single conversion host creation via action" do
      api_basic_authorize(collection_action_identifier(:conversion_hosts, :create))

      post(api_conversion_hosts_url, :params => gen_request(:create, sample_conversion_host_from_vm))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)

      conversion_host_id = response.parsed_body["results"].first["id"]
      expect(ConversionHost.find_by(:resource_id => vm.id).id).to eql(conversion_host_id.to_i)
    end

    it "supports multiple conversion host creation" do
      api_basic_authorize(collection_action_identifier(:conversion_hosts, :create))

      conversion_hosts = [sample_conversion_host_from_vm, sample_conversion_host_from_host]
      post(api_conversion_hosts_url, :params => gen_request(:create, conversion_hosts))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)

      results = response.parsed_body["results"]

      expect(ConversionHost.exists?(results.first["id"])).to be_truthy
      expect(ConversionHost.exists?(results.last["id"])).to be_truthy
      expect(results).to match_array([a_hash_including("resource_id" => vm.id.to_s), a_hash_including("resource_id" => host.id.to_s)])
    end
  end

  context "delete" do
    let(:conversion_host)             { FactoryGirl.create(:conversion_host) }
    let(:conversion_host_url)         { api_conversion_host_url(nil, conversion_host) }
    let(:invalid_conversion_host_url) { api_conversion_host_url(nil, 999_999) }

    it "can delete a conversion host via DELETE" do
      api_basic_authorize(action_identifier(:conversion_hosts, :delete))
      delete(conversion_host_url)

      expect(response).to have_http_status(:no_content)
      expect(ConversionHost.exists?(conversion_host.id)).to be_falsey
    end

    it "can delete a conversion host via POST" do
      api_basic_authorize(action_identifier(:conversion_hosts, :delete, :resource_actions))
      post(conversion_host_url, :params => gen_request(:delete))

      expect_single_action_result(:success => true, :message => "deleting", :href => conversion_host_url)
      expect(ConversionHost.exists?(conversion_host.id)).to be_falsey
    end

    it "will not delete a conversion host unless authorized" do
      api_basic_authorize
      delete(conversion_host_url)

      expect(response).to have_http_status(:forbidden)
      expect(ConversionHost.exists?(conversion_host.id)).to be_truthy
    end

    it "can delete multiple conversion hosts" do
      api_basic_authorize(collection_action_identifier(:conversion_hosts, :delete))
      chost1, chost2 = FactoryGirl.create_list(:conversion_host, 2)

      chost1_id, chost2_id = chost1.id, chost2.id
      chost1_url = api_conversion_host_url(nil, chost1_id)
      chost2_url = api_conversion_host_url(nil, chost2_id)

      post(api_conversion_hosts_url, :params => gen_request(:delete, [{"href" => chost1_url}, {"href" => chost2_url}]))

      array = []
      array << api_conversion_host_url(nil, chost1)
      array << api_conversion_host_url(nil, chost2)

      expect_multiple_action_result(2)
      expect_result_resources_to_include_hrefs("results", array)
      expect(ConversionHost.exists?(chost1.id)).to be_falsey
      expect(ConversionHost.exists?(chost2.id)).to be_falsey
    end
  end

  context "polymorphic resource" do
    let(:vm) { FactoryGirl.create(:vm, :name => "polymorphic_vm") }
    let(:host) { FactoryGirl.create(:host, :name => "polymorphic_host") }
    let(:conversion_host_resource_vm) { FactoryGirl.create(:conversion_host, :resource_type => "Vm", :resource_id => vm.id) }
    let(:conversion_host_resource_host) { FactoryGirl.create(:conversion_host, :resource_type => "Host", :resource_id => host.id) }

    it "retrieves the Vm polymorphic resource as expected" do
      api_basic_authorize(resource_action_identifier(:conversion_hosts, :resource))
      url = api_conversion_host_url(nil, conversion_host_resource_vm)
      post(url, :params => {:action => 'resource'})

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('href' => api_vm_url(nil, vm))
    end

    it "retrieves the Host polymorphic resource as expected" do
      api_basic_authorize(resource_action_identifier(:conversion_hosts, :resource))
      url = api_conversion_host_url(nil, conversion_host_resource_host)
      post(url, :params => {:action => 'resource'})

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('href' => api_host_url(nil, host))
    end
  end

  context "tags" do
    let(:tag1) { {:category => "department", :name => "finance", :path => "/managed/department/finance"} }
    let(:tag2) { {:category => "cc",         :name => "001",     :path => "/managed/cc/001"} }

    let(:invalid_tag_url) { api_tag_url(nil, 999_999) }

    let(:conversion_host) { FactoryGirl.create(:conversion_host, :name => 'conversion_host_with_tags') }

    before do
      FactoryGirl.create(:classification_department_with_tags)
      FactoryGirl.create(:classification_cost_center_with_tags)
    end

    it "can list the tags for a conversion host" do
      Classification.classify(conversion_host, tag1[:category], tag1[:name])
      api_basic_authorize
      get(api_conversion_host_tags_url(nil, conversion_host))

      expect(response.parsed_body).to include("subcount" => 1)
      expect(response).to have_http_status(:ok)
    end

    it "can assign a tag to a conversion host" do
      api_basic_authorize(subcollection_action_identifier(:conversion_hosts, :tags, :assign))

      post(api_conversion_host_tags_url(nil, conversion_host), :params => { :action => "assign", :category => "department", :name => "finance" })

      expected = {
        "results" => [
          a_hash_including(
            "success"      => true,
            "message"      => a_string_matching(/assigning tag/i),
            "tag_category" => "department",
            "tag_name"     => "finance"
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)

      tag = Tag.find_by(:name => '/managed/department/finance')
      expect(tag).to be_truthy
      expect(ConversionHost.find_by(:name => 'conversion_host_with_tags').tags).to include(tag)
    end

    it "can unassign a tag from a conversion host" do
      Classification.classify(conversion_host, tag1[:category], tag1[:name])
      api_basic_authorize(subcollection_action_identifier(:conversion_hosts, :tags, :unassign))

      post(api_conversion_host_tags_url(nil, conversion_host), :params => { :action => "unassign", :category => "department", :name => "finance" })

      expected = {
        "results" => [
          a_hash_including(
            "success"      => true,
            "message"      => a_string_matching(/unassigning tag/i),
            "tag_category" => "department",
            "tag_name"     => "finance"
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "assigns multiple tags to a conversion_host" do
      api_basic_authorize subcollection_action_identifier(:conversion_hosts, :tags, :assign)

      post(api_conversion_host_tags_url(nil, conversion_host), :params => gen_request(:assign, [{:name => tag1[:path]}, {:name => tag2[:path]}]))

      expect_tagging_result(
        [{:success => true, :href => api_conversion_host_url(nil, conversion_host), :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => api_conversion_host_url(nil, conversion_host), :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      )
    end

    it "assigns tags by mixed specification to a conversion_host" do
      api_basic_authorize subcollection_action_identifier(:conversion_hosts, :tags, :assign)

      tag = Tag.find_by(:name => tag2[:path])
      post(api_conversion_host_tags_url(nil, conversion_host), :params => gen_request(:assign, [{:name => tag1[:path]}, {:href => api_tag_url(nil, tag)}]))

      expect_tagging_result(
        [{:success => true, :href => api_conversion_host_url(nil, conversion_host), :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => api_conversion_host_url(nil, conversion_host), :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      )
    end

    it "unassigns multiple tags from a conversion_host" do
      Classification.classify(conversion_host, tag2[:category], tag2[:name])

      api_basic_authorize subcollection_action_identifier(:conversion_hosts, :tags, :unassign)

      tag = Tag.find_by(:name => tag2[:path])
      post(api_conversion_host_tags_url(nil, conversion_host), :params => gen_request(:unassign, [{:name => tag1[:path]}, {:href => api_tag_url(nil, tag)}]))

      expect_tagging_result(
        [{:success => true, :href => api_conversion_host_url(nil, conversion_host), :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => api_conversion_host_url(nil, conversion_host), :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      )
      expect(conversion_host.tags.count).to eq(0)
    end
  end
end
