RSpec.describe 'Lans API' do
  context "Lan Tag subcollection" do
    let(:tag1)         { {:category => "department", :name => "finance", :path => "/managed/department/finance"} }
    let(:tag2)         { {:category => "cc",         :name => "001",     :path => "/managed/cc/001"} }

    let(:lan1) { FactoryBot.create(:lan) }
    let(:lan1_url) { api_lan_url(nil, lan1) }

    let(:lan2) { FactoryBot.create(:lan) }
    let(:lan2_url) { api_lan_url(nil, lan2) }

    let(:invalid_tag_url) { api_tag_url(nil, 999_999) }

    before do
      FactoryBot.create(:classification_department_with_tags)
      FactoryBot.create(:classification_cost_center_with_tags)
      Classification.classify(lan2, tag1[:category], tag1[:name])
      Classification.classify(lan2, tag2[:category], tag2[:name])
    end

    it "query all tags of a Lan with no tags" do
      api_basic_authorize

      get api_lan_tags_url(nil, lan1)

      expect_empty_query_result(:tags)
    end

    it "query all tags of a Lan" do
      api_basic_authorize

      get api_lan_tags_url(nil, lan2)

      expect_query_result(:tags, 2, Tag.count)
    end

    it "query all tags of a Lan and verify tag category and names" do
      api_basic_authorize

      get api_lan_tags_url(nil, lan2), :params => {:expand => "resources"}

      expect_query_result(:tags, 2, Tag.count)
      expect_result_resources_to_include_data("resources", "name" => [tag1[:path], tag2[:path]])
    end

    it "query lans by tag name via filter[]=tags.name" do
      api_basic_authorize collection_action_identifier(:lans, :read, :get)
      # let's make sure both lans are created
      lan1
      lan2

      get api_lans_url, :params => {:expand => "resources", :filter => ["tags.name='#{tag2[:path]}'"]}

      expect_query_result(:lans, 1, 2)
      expect_result_resources_to_include_hrefs("resources", [api_lan_url(nil, lan2)])
    end

    it "assigns a tag to a Lan without appropriate role" do
      api_basic_authorize

      post(api_lan_tags_url(nil, lan1), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "assigns a tag to a Lan" do
      api_basic_authorize subcollection_action_identifier(:lans, :tags, :assign)

      post(api_lan_tags_url(nil, lan1), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(
        [{:success => true, :href => api_lan_url(nil, lan1), :tag_category => tag1[:category], :tag_name => tag1[:name]}]
      )
    end

    it "assigns a tag to a Lan by name path" do
      api_basic_authorize subcollection_action_identifier(:lans, :tags, :assign)

      post(api_lan_tags_url(nil, lan1), :params => gen_request(:assign, :name => tag1[:path]))

      expect_tagging_result(
        [{:success => true, :href => api_lan_url(nil, lan1), :tag_category => tag1[:category], :tag_name => tag1[:name]}]
      )
    end

    it "assigns a tag to a Lan by href" do
      api_basic_authorize subcollection_action_identifier(:lans, :tags, :assign)

      post(api_lan_tags_url(nil, lan1), :params => gen_request(:assign, :href => api_tag_url(nil, Tag.find_by(:name => tag1[:path]))))

      expect_tagging_result(
        [{:success => true, :href => api_lan_url(nil, lan1), :tag_category => tag1[:category], :tag_name => tag1[:name]}]
      )
    end

    it "assigns an invalid tag by href to a Lan" do
      api_basic_authorize subcollection_action_identifier(:lans, :tags, :assign)

      post(api_lan_tags_url(nil, lan1), :params => gen_request(:assign, :href => invalid_tag_url))

      expect(response).to have_http_status(:not_found)
    end

    it "assigns an invalid tag to a Lan" do
      api_basic_authorize subcollection_action_identifier(:lans, :tags, :assign)

      post(api_lan_tags_url(nil, lan1), :params => gen_request(:assign, :name => "/managed/bad_category/bad_name"))

      expect_tagging_result(
        [{:success => false, :href => api_lan_url(nil, lan1), :tag_category => "bad_category", :tag_name => "bad_name"}]
      )
    end

    it "assigns multiple tags to a Lan" do
      api_basic_authorize subcollection_action_identifier(:lans, :tags, :assign)

      post(api_lan_tags_url(nil, lan1), :params => gen_request(:assign, [{:name => tag1[:path]}, {:name => tag2[:path]}]))

      expect_tagging_result(
        [{:success => true, :href => api_lan_url(nil, lan1), :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => api_lan_url(nil, lan1), :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      )
    end

    it "assigns tags by mixed specification to a Lan" do
      api_basic_authorize subcollection_action_identifier(:lans, :tags, :assign)

      tag = Tag.find_by(:name => tag2[:path])
      post(api_lan_tags_url(nil, lan1), :params => gen_request(:assign, [{:name => tag1[:path]}, {:href => api_tag_url(nil, tag)}]))

      expect_tagging_result(
        [{:success => true, :href => api_lan_url(nil, lan1), :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => api_lan_url(nil, lan1), :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      )
    end

    it "unassigns a tag from a Lan without appropriate role" do
      api_basic_authorize

      post(api_lan_tags_url(nil, lan1), :params => gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))

      expect(response).to have_http_status(:forbidden)
    end

    it "unassigns a tag from a Lan" do
      api_basic_authorize subcollection_action_identifier(:lans, :tags, :unassign)

      post(api_lan_tags_url(nil, lan2), :params => gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))

      expect_tagging_result(
        [{:success => true, :href => api_lan_url(nil, lan2), :tag_category => tag1[:category], :tag_name => tag1[:name]}]
      )
      expect(lan2.tags.count).to eq(1)
      expect(lan2.tags.first.name).to eq(tag2[:path])
    end

    it "unassigns multiple tags from a Lan" do
      api_basic_authorize subcollection_action_identifier(:lans, :tags, :unassign)

      tag = Tag.find_by(:name => tag2[:path])
      post(api_lan_tags_url(nil, lan2), :params => gen_request(:unassign, [{:name => tag1[:path]}, {:href => api_tag_url(nil, tag)}]))

      expect_tagging_result(
        [{:success => true, :href => api_lan_url(nil, lan2), :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => api_lan_url(nil, lan2), :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      )
      expect(lan2.tags.count).to eq(0)
    end
  end

  describe 'GET /api/lans' do
    it 'returns all lans with an appropriate role' do
      lan = FactoryBot.create(:lan)
      api_basic_authorize collection_action_identifier(:lans, :read, :get)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'lans',
        'resources' => [
          hash_including('href' => api_lan_url(nil, lan))
        ]
      }
      get(api_lans_url)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids access to lans without an appropriate role' do
      api_basic_authorize

      get(api_lans_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/lans/:id' do
    let(:lan) { FactoryBot.create(:lan) }

    it 'will show a lan with an appropriate role' do
      api_basic_authorize action_identifier(:lans, :read, :resource_actions, :get)

      get(api_lan_url(nil, lan))

      expect(response.parsed_body).to include('href' => api_lan_url(nil, lan))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to a lan without an appropriate role' do
      api_basic_authorize

      get(api_lan_url(nil, lan))

      expect(response).to have_http_status(:forbidden)
    end
  end
end
