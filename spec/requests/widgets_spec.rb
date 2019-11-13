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
    let(:miq_widget) { FactoryBot.create(:miq_widget, :visibility => {:roles => '_ALL_'}, :resource => MiqReport.first) }
    let(:second_miq_widget) { FactoryBot.create(:miq_widget, :visibility => {:roles => '_ALL_'}, :resource => MiqReport.first) }
    let(:feature1) { MiqProductFeature.find_all_by_identifier("dashboard_admin") }
    let(:user1) { FactoryBot.create(:user, :role => "role1", :features => feature1) }
    let(:group1) { user1.current_group }
    let(:ws) { FactoryBot.create(:miq_widget_set, :name => "Home", :userid => user1.userid, :group_id => group1.id) }

    before do
      MiqReport.seed_report("Vendor and Guest OS")
      miq_widget.make_memberof(ws)
    end

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

      context "generate_content for group" do
        before do
          api_basic_authorize('widget_generate_content')
          stub_settings(::Settings.to_hash.merge(:product => {:report_sync => true}))
        end

        it "generates single widget content" do
          expect(miq_widget.miq_widget_contents.count).to eq(0)
          post(api_widget_url(nil, miq_widget), :params => gen_request(:generate_content))
          expect(response).to have_http_status(:ok)
          expect(miq_widget.miq_widget_contents.count).to eq(1)
        end

        it "generates multiple widget contents" do
          second_miq_widget.make_memberof(ws)

          post(api_widgets_url, :params => gen_request(:generate_content, [{"href" => api_widget_url(nil, miq_widget)}, {"href" => api_widget_url(nil, second_miq_widget)}]))

          expect(response).to have_http_status(:ok)
          expect(miq_widget.miq_widget_contents.count).to eq(1)
          expect(second_miq_widget.miq_widget_contents.count).to eq(1)
        end
      end

      context "generate_content for user" do
        before do
          api_basic_authorize('widget_generate_content')
        end

        it "generates single widget content" do
          expect(miq_widget.miq_widget_contents.count).to eq(0)
          post(api_widget_url(nil, miq_widget), :params => gen_request(:generate_content))

          expect(response).to have_http_status(:ok)
          expect(MiqTask.count).to eq(1)
          expect(MiqQueue.count).to eq(1)
        end

        it "generates multiple widget contents" do
          second_miq_widget.make_memberof(ws)

          expect(MiqTask.count).to eq(0)
          post(api_widgets_url, :params => gen_request(:generate_content, [{"href" => api_widget_url(nil, miq_widget)}, {"href" => api_widget_url(nil, second_miq_widget)}]))

          expect(response).to have_http_status(:ok)
          expect(MiqTask.count).to eq(2)
          expect(MiqQueue.count).to eq(2)
        end
      end
    end
  end
end
