RSpec.describe "categories API" do
  it "can list all the categories" do
    categories = FactoryBot.create_list(:category, 2)
    api_basic_authorize collection_action_identifier(:categories, :read, :get)

    get api_categories_url

    expect_result_resources_to_include_hrefs(
      "resources",
      categories.map { |category| api_category_url(nil, category) }
    )
    expect(response).to have_http_status(:ok)
  end

  it "can filter the list of categories by name" do
    category_1 = FactoryBot.create(:category, :name => "foo")
    _category_2 = FactoryBot.create(:category, :name => "bar")
    api_basic_authorize collection_action_identifier(:categories, :read, :get)

    get api_categories_url, :params => { :filter => ["name=foo"] }

    expect_query_result(:categories, 1, 2)
    expect_result_resources_to_include_hrefs("resources", [api_category_url(nil, category_1)])
  end

  it "will return a bad request error if the filter name is invalid" do
    FactoryBot.create(:category)
    api_basic_authorize collection_action_identifier(:categories, :read, :get)

    get api_categories_url, :params => { :filter => ["not_an_attribute=foo"] }

    expect_bad_request(/attribute not_an_attribute does not exist/)
  end

  it "can read a category" do
    category = FactoryBot.create(:category)
    api_basic_authorize action_identifier(:categories, :read, :resource_actions, :get)

    get api_category_url(nil, category)
    expect_result_to_match_hash(
      response.parsed_body,
      "description" => category.description,
      "href"        => api_category_url(nil, category),
      "id"          => category.id.to_s
    )
    expect(response).to have_http_status(:ok)
  end

  it "will only return the requested attributes" do
    FactoryBot.create(:category, :example_text => 'foo')
    api_basic_authorize collection_action_identifier(:categories, :read, :get)

    get api_categories_url, :params => { :expand => 'resources', :attributes => 'example_text' }

    expect(response).to have_http_status(:ok)
    response.parsed_body['resources'].each { |res| expect_hash_to_have_only_keys(res, %w(href id example_text)) }
  end

  it "can list all the tags under a category" do
    classification = FactoryBot.create(:classification_tag)
    category = FactoryBot.create(:category, :children => [classification])
    tag = classification.tag
    FactoryBot.create(:classification, :name => "some_other_tag")
    api_basic_authorize

    get(api_category_tags_url(nil, category))

    expect_result_resources_to_include_hrefs(
      "resources",
      [api_category_tag_url(nil, category, tag)]
    )
    expect(response).to have_http_status(:ok)
  end

  context "with an appropriate role" do
    it "can create a category" do
      api_basic_authorize collection_action_identifier(:categories, :create)

      expect do
        post api_categories_url, :params => { :name => "test", :description => "Test" }
      end.to change(Category, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "can set read_only/show/single_value when creating a category" do
      api_basic_authorize collection_action_identifier(:categories, :create)

      options = {
        :name         => "test",
        :description  => "test",
        :read_only    => true,
        :show         => true,
        :single_value => true
      }
      post api_categories_url, :params => options

      expect_result_to_match_hash(
        response.parsed_body["results"].first,
        "read_only"    => true,
        "show"         => true,
        "single_value" => true
      )
    end

    it "can create an associated tag" do
      api_basic_authorize collection_action_identifier(:categories, :create)

      post api_categories_url, :params => { :name => "test", :description => "Test" }
      category = Category.find(response.parsed_body["results"].first["id"])

      expect(category.tag.name).to eq("/managed/test")
    end

    it "can update a category" do
      category = FactoryBot.create(:category)
      api_basic_authorize action_identifier(:categories, :edit)

      expect do
        post api_category_url(nil, category), :params => gen_request(:edit, :description => "New description")
      end.to change { category.reload.description }.to("New description")

      expect(response).to have_http_status(:ok)
      expect_result_to_have_keys(%w(id description name))
    end

    it "can delete a category through POST" do
      category = FactoryBot.create(:category)
      api_basic_authorize action_identifier(:categories, :delete)

      expect do
        post api_category_url(nil, category), :params => gen_request(:delete)
      end.to change(Category, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it "can delete a category through DELETE" do
      category = FactoryBot.create(:category)
      api_basic_authorize action_identifier(:categories, :delete)

      expect do
        delete api_category_url(nil, category)
      end.to change(Category, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    context "read-only categories" do
      it "can't delete a read-only category" do
        category = FactoryBot.create(:category, :read_only => true)
        api_basic_authorize action_identifier(:categories, :delete)

        expect do
          post api_category_url(nil, category), :params => gen_request(:delete)
        end.not_to change(Category, :count)

        expect(response).to have_http_status(:forbidden)
      end

      it "can't update a read-only category" do
        category = FactoryBot.create(:category, :description => "old description", :read_only => true)
        api_basic_authorize action_identifier(:categories, :edit)

        expect do
          post api_category_url(nil, category), :params => gen_request(:edit, :description => "new description")
        end.not_to change { category.reload.description }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without an appropriate role" do
      it "cannot create a category" do
        api_basic_authorize

        expect do
          post api_categories_url, :params => { :name => "test", :description => "Test" }
        end.not_to change(Category, :count)

        expect(response).to have_http_status(:forbidden)
      end

      it "cannot update a category" do
        category = FactoryBot.create(:category)
        api_basic_authorize

        expect do
          post api_category_url(nil, category), :params => gen_request(:edit, :description => "New description")
        end.not_to change { category.reload.description }

        expect(response).to have_http_status(:forbidden)
      end

      it "cannot delete a category through POST" do
        category = FactoryBot.create(:category)
        api_basic_authorize

        expect do
          post api_category_url(nil, category), :params => gen_request(:delete)
        end.not_to change(Category, :count)

        expect(response).to have_http_status(:forbidden)
      end

      it "cannot delete a category through DELETE" do
        category = FactoryBot.create(:category)
        api_basic_authorize

        expect do
          delete api_category_url(nil, category)
        end.not_to change(Category, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
