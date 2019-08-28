#
# REST API Request Tests - /api/tags
#
describe "Tags API" do
  let(:tag1)         { {:category => "department", :name => "finance", :path => "/managed/department/finance"} }
  let(:tag2)         { {:category => "cc",         :name => "001",     :path => "/managed/cc/001"} }
  let(:invalid_tag_url) { api_tag_url(nil, 999_999) }

  before(:each) do
    FactoryBot.create(:classification_department_with_tags)
    FactoryBot.create(:classification_cost_center_with_tags)
  end

  context "Tag collection" do
    it "query all tags" do
      api_basic_authorize collection_action_identifier(:tags, :read, :get)

      get api_tags_url

      expect_query_result(:tags, Classification.count)
    end

    context "with an appropriate role" do
      it "can create a tag with category by href" do
        api_basic_authorize collection_action_identifier(:tags, :create)
        category = FactoryBot.create(:classification)
        options = {:name => "test_tag", :description => "Test Tag", :category => {:href => api_category_url(nil, category)}}

        expect { post api_tags_url, :params => options }.to change(Classification, :count).by(1)

        result = response.parsed_body["results"].first
        tag = Classification.find_by!(:tag_id => result["id"]).tag
        tag_category = tag.category
        expect(tag_category).to eq(category)
        expect(result["href"]).to include(api_tag_url(nil, tag))
        expect(response).to have_http_status(:ok)
      end

      it "can create a tag with a category by id" do
        api_basic_authorize collection_action_identifier(:tags, :create)
        category = FactoryBot.create(:classification)

        expect do
          post api_tags_url, :params => { :name => "test_tag", :description => "Test Tag", :category => {:id => category.id} }
        end.to change(Classification, :count).by(1)

        tag = Classification.find_by!(:tag_id => response.parsed_body["results"].first["id"]).tag
        tag_category = tag.category
        expect(tag_category).to eq(category)

        expect(response).to have_http_status(:ok)
      end

      it "can create a tag with a category by name" do
        api_basic_authorize collection_action_identifier(:tags, :create)
        category = FactoryBot.create(:classification)

        expect do
          post api_tags_url, :params => { :name => "test_tag", :description => "Test Tag", :category => {:name => category.name} }
        end.to change(Classification, :count).by(1)

        tag = Classification.find_by!(:tag_id => response.parsed_body["results"].first["id"]).tag
        tag_category = tag.category
        expect(tag_category).to eq(category)

        expect(response).to have_http_status(:ok)
      end

      it "can create a tag as a subresource of a category" do
        api_basic_authorize collection_action_identifier(:tags, :create)
        category = FactoryBot.create(:classification)

        expect do
          post(api_category_tags_url(nil, category), :params => { :name => "test_tag", :description => "Test Tag" })
        end.to change(Classification, :count).by(1)
        tag = Classification.find_by!(:tag_id => response.parsed_body["results"].first["id"]).tag
        tag_category = tag.category
        expect(tag_category).to eq(category)

        expect(response).to have_http_status(:ok)
      end

      it "returns bad request when the category doesn't exist" do
        api_basic_authorize collection_action_identifier(:tags, :create)

        post api_tags_url, :params => { :name => "test_tag", :description => "Test Tag" }

        expect(response).to have_http_status(:bad_request)
      end

      it "can update a tag's name" do
        api_basic_authorize action_identifier(:tags, :edit)
        classification = FactoryBot.create(:classification_tag)
        category = FactoryBot.create(:category, :children => [classification])
        tag = classification.tag

        expect do
          post api_tag_url(nil, tag), :params => gen_request(:edit, :name => "new_name")
        end.to change { classification.reload.tag.name }.to("#{category.tag.name}/new_name")
        expect(response.parsed_body["name"]).to eq("#{category.tag.name}/new_name")
        expect(response).to have_http_status(:ok)
      end

      it "can update a tag's description" do
        api_basic_authorize action_identifier(:tags, :edit)
        classification = FactoryBot.create(:classification_tag)
        FactoryBot.create(:category, :children => [classification])
        tag = classification.tag

        expect do
          post api_tag_url(nil, classification.tag), :params => gen_request(:edit, :description => "New Description")
        end.to change { classification.reload.description }.to("New Description")

        expect(response).to have_http_status(:ok)
      end

      it "can delete a tag through POST" do
        api_basic_authorize action_identifier(:tags, :delete)
        classification = FactoryBot.create(:classification_tag)
        tag = classification.tag

        expect { post api_tag_url(nil, tag), :params => { :action => :delete } }.to change(Classification, :count).by(-1)
        expect { classification.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to have_http_status(:ok)
      end

      it "can delete a tag through DELETE" do
        api_basic_authorize action_identifier(:tags, :delete)
        classification = FactoryBot.create(:classification_tag)
        tag = classification.tag

        expect { delete api_tag_url(nil, tag) }.to change(Classification, :count).by(-1)
        expect { classification.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to have_http_status(:no_content)
      end

      it "will respond with 404 not found when deleting a non-existent tag through DELETE" do
        api_basic_authorize action_identifier(:tags, :delete)
        classification = FactoryBot.create(:classification_tag)
        tag_id = classification.tag.id
        classification.destroy!

        delete api_tag_url(nil, tag_id)

        expect(response).to have_http_status(:not_found)
      end

      it "will respond with 404 not found when deleting a non-existent tag through POST" do
        api_basic_authorize action_identifier(:tags, :delete)
        classification = FactoryBot.create(:classification_tag)
        tag_id = classification.tag.id
        classification.destroy!

        post api_tag_url(nil, tag_id), :params => { :action => :delete }

        expect(response).to have_http_status(:not_found)
      end

      it "can delete multiple tags within a category by id" do
        api_basic_authorize action_identifier(:tags, :delete)
        classification1 = FactoryBot.create(:classification_tag)
        classification2 = FactoryBot.create(:classification_tag)
        category = FactoryBot.create(:category, :children => [classification1, classification2])
        tag1 = classification1.tag
        tag2 = classification2.tag

        expect do
          post(api_category_tags_url(nil, category), :params => gen_request(:delete, [{:id => tag1.id}, {:id => tag2.id}]))
        end.to change(Classification, :count).by(-2)
        expect { classification1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { classification2.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect_result_to_match_hash(
          response.parsed_body,
          "results" => [
            {"success" => true, "message" => "tags id: #{tag1.id} deleting"},
            {"success" => true, "message" => "tags id: #{tag2.id} deleting"}
          ]
        )
        expect(response).to have_http_status(:ok)
      end

      it "can delete multiple tags within a category by name" do
        api_basic_authorize action_identifier(:tags, :delete)
        classification1 = FactoryBot.create(:classification_tag)
        classification2 = FactoryBot.create(:classification_tag)
        category = FactoryBot.create(:category, :children => [classification1, classification2])
        tag1 = classification1.tag
        tag2 = classification2.tag
        body = gen_request(:delete, [{:name => tag1.name}, {:name => tag2.name}])

        expect do
          post(api_category_tags_url(nil, category), :params => body)
        end.to change(Classification, :count).by(-2)
        expect { classification1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { classification2.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect_result_to_match_hash(
          response.parsed_body,
          "results" => [
            {"success" => true, "message" => "tags id: #{tag1.id} deleting"},
            {"success" => true, "message" => "tags id: #{tag2.id} deleting"}
          ]
        )
        expect(response).to have_http_status(:ok)
      end
    end

    context "without an appropriate role" do
      it "cannot create a new tag" do
        api_basic_authorize

        expect do
          post api_tags_url, :params => { :name => "test_tag", :description => "Test Tag" }
        end.not_to change(Classification, :count)

        expect(response).to have_http_status(:forbidden)
      end

      it "cannot update a tag" do
        api_basic_authorize
        classification = FactoryBot.create(:classification)
        tag = classification.tag

        expect do
          post api_tag_url(nil, tag), :params => gen_request(:edit, :name => "new_name")
        end.not_to change { classification.reload.name }

        expect(response).to have_http_status(:forbidden)
      end

      it "cannot delete a tag through POST" do
        api_basic_authorize
        tag = FactoryBot.create(:classification).tag

        expect { post api_tag_url(nil, tag), :params => { :action => :delete } }.not_to change(Classification, :count)

        expect(response).to have_http_status(:forbidden)
      end

      it "cannot delete a tag through DELETE" do
        api_basic_authorize
        tag = FactoryBot.create(:classification).tag

        expect { delete api_tag_url(nil, tag) }.not_to change(Classification, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    it "query a tag with an invalid Id" do
      api_basic_authorize action_identifier(:tags, :read, :resource_actions, :get)

      get invalid_tag_url

      expect(response).to have_http_status(:not_found)
    end

    it "query tags with expanded resources" do
      api_basic_authorize collection_action_identifier(:tags, :read, :get)

      get api_tags_url, :params => { :expand => "resources" }

      expect_query_result(:tags, Classification.count, Classification.count)
      expect_result_resources_to_include_keys("resources", %w(id name))
    end

    it "query tag details with multiple virtual attributes" do
      api_basic_authorize action_identifier(:tags, :read, :resource_actions, :get)

      tag = Classification.is_entry.last.tag
      attr_list = "category.name,category.description,classification.name,classification.description"
      get api_tag_url(nil, tag), :params => { :attributes => attr_list }

      expect_single_resource_query(
        "href"           => api_tag_url(nil, tag),
        "id"             => tag.id.to_s,
        "name"           => tag.name,
        "category"       => {"name" => tag.category.name,       "description" => tag.category.description},
        "classification" => {"name" => tag.classification.name, "description" => tag.classification.description}
      )
    end

    it "query tag details with categorization" do
      api_basic_authorize action_identifier(:tags, :read, :resource_actions, :get)

      tag = Classification.is_entry.last.tag
      get api_tag_url(nil, tag), :params => { :attributes => "categorization" }

      expect_single_resource_query(
        "href"           => api_tag_url(nil, tag),
        "id"             => tag.id.to_s,
        "name"           => tag.name,
        "categorization" => {
          "name"         => tag.classification.name,
          "description"  => tag.classification.description,
          "display_name" => "#{tag.category.description}: #{tag.classification.description}",
          "category"     => {"name" => tag.category.name, "description" => tag.category.description}
        }
      )
    end

    it "query all tags with categorization" do
      api_basic_authorize action_identifier(:tags, :read, :resource_actions, :get)

      get api_tags_url, :params => { :expand => "resources", :attributes => "categorization" }

      expect_query_result(:tags, Classification.count, Classification.count)
      expect_result_resources_to_include_keys("resources", %w(id name categorization))
    end
  end
end
