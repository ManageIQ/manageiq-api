describe "Widgets API" do
  context "GET /api/widgets" do
    it "returns all Widgets" do
      miq_widget = FactoryBot.create(:miq_widget)
      api_basic_authorize('miq_widget_show_list')

      get(api_widgets_url)

      expected = {
        "name"      => "widgets",
        "resources" => [{"href" => api_widget_url(nil, miq_widget)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/miq_widgets/:id" do
    it "returns a single Widget" do
      miq_widget = FactoryBot.create(:miq_widget)
      api_basic_authorize('miq_widget_show')

      get(api_widget_url(nil, miq_widget))

      expected = {
        "description" => miq_widget.name,
        "href"        => api_widget_url(nil, miq_widget)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe "Widgets generate_content action" do
    context "with an invalid id" do
      it "it responds with 404 Not Found" do
        api_basic_authorize(action_identifier(:widgets, :generate_content, :resource_actions, :post))

        post(api_widget_url(nil, 999_999), :params => gen_request(:generate_content))

        expect(response).to have_http_status(:not_found)
      end
    end

    context "without an appropriate role" do
      it "it responds with 403 Forbidden" do
        miq_widget = FactoryBot.create(:miq_widget)
        api_basic_authorize

        post(api_widget_url(nil, miq_widget), :params => gen_request(:generate_content))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an appropriate role" do
      it "rejects generate_content for an unspecified Widget" do
        api_basic_authorize(action_identifier(:widgets, :generate_content, :resource_actions, :post))

        post(api_widgets_url, :params => gen_request(:generate_content, [{"href" => api_widgets_url}, {"href" => api_widgets_url}]))

        expect(response).to have_http_status(:not_found)
      end

      it "generate_content of a single Widget" do
        miq_widget = FactoryBot.create(:miq_widget)

        api_basic_authorize('widget_generate_content')

        expect(MiqTask.count).to eq(0)
        post(api_widget_url(nil, miq_widget), :params => gen_request(:generate_content))

        expect_single_action_result(:success => true, :message => /#{miq_widget.id}.* content generation/i, :href => api_widget_url(nil, miq_widget))
        expect(MiqTask.first.message).to match(/content generation\]\ being run for user/)
      end

      it "generate_content of multiple Widgets" do
        first_miq_widget = FactoryBot.create(:miq_widget)
        second_miq_widget = FactoryBot.create(:miq_widget)
        api_basic_authorize('widget_generate_content')
        expect(MiqTask.count).to eq(0)

        post(api_widgets_url, :params => gen_request(:generate_content, [{"href" => api_widget_url(nil, first_miq_widget)}, {"href" => api_widget_url(nil, second_miq_widget)}]))

        expected = {
          "results" => a_collection_containing_exactly(
            a_hash_including(
              "message" => a_string_matching(/#{first_miq_widget.id}.* content generation/i),
              "success" => true,
              "href"    => api_widget_url(nil, first_miq_widget)
            ),
            a_hash_including(
              "message" => a_string_matching(/#{second_miq_widget.id}.* content generation/i),
              "success" => true,
              "href"    => api_widget_url(nil, second_miq_widget)
            )
          )
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
        expect(MiqTask.count).to eq(2)
      end
    end
  end
end
