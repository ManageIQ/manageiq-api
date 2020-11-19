describe "Widget Sets API" do
  let(:group) { User.current_user.current_group }
  let(:miq_widget_set)       { FactoryBot.create(:miq_widget_set, :set_data_with_one_widget, :owner => group) }
  let(:miq_widget_set_other) { FactoryBot.create(:miq_widget_set, :set_data_with_one_widget, :owner => group) }
  let(:widgets) { FactoryBot.create_list(:miq_widget, 3) }
  let(:widget_params) do
    {
      "name"        => "XXX",
      "description" => "YYY",
      "set_data"    => {"col1"             => widgets.map(&:id),
                        "reset_upon_login" => false,
                        "locked"           => false}
    }
  end

  before do
    User.current_user = User.first
  end

  context "GET" do
    it "returns single" do
      api_basic_authorize collection_action_identifier(:widget_sets, :read, :get)

      get(api_widget_set_url(nil, miq_widget_set))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id'].to_i).to eq(miq_widget_set.id)
    end

    it "returns all widget sets" do
      api_basic_authorize collection_action_identifier(:widget_sets, :read, :get)

      get(api_widget_sets_url)

      expect(response).to have_http_status(:ok)
      widget_sets_hrefs = response.parsed_body['resources'].map { |x| x['href'] }
      all_widget_sets_hrefs = MiqWidgetSet.all.map { |ws| api_widget_set_url(nil, ws) }
      expect(widget_sets_hrefs).to match_array(all_widget_sets_hrefs)
    end

    it "doesn't find widget set" do
      api_basic_authorize collection_action_identifier(:widget_sets, :read, :get)

      get(api_widget_set_url(nil, 999_999))

      expect(response).to have_http_status(:not_found)
    end

    it "forbids action get for non-super-admin user" do
      expect_forbidden_request do
        get(api_widget_set_url(nil, miq_widget_set))
      end
    end
  end

  context "POST" do
    let(:group_href) { api_group_url(nil, group) }

    it "creates widget set" do
      api_basic_authorize collection_action_identifier(:widget_sets, :create, :post)

      post api_widget_sets_url, :params => gen_request(:create, widget_params.merge('group' => {'href' => group_href}))

      expect(response).to have_http_status(:ok)

      widget_params["set_data"]["col2"] = []
      widget_params["set_data"]["col3"] = []
      expect(response.parsed_body['results'][0].values_at(*widget_params.keys)).to match_array(widget_params.values)
      ws = MiqWidgetSet.find(response.parsed_body['results'][0]['id'])
      expect(ws.members.map(&:id)).to eq(widgets.map(&:id))
      group.reload
      expect(group.settings["dashboard_order"]).to eq([ws.id])
    end

    it "updates widget set" do
      api_basic_authorize collection_action_identifier(:widget_sets, :edit, :post)

      widget_params_for_update = widget_params.except('name')
      post api_widget_set_url(nil, miq_widget_set), :params => gen_request(:edit, widget_params_for_update)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id'].to_i).to eq(miq_widget_set.id)
      widget_params["set_data"]["col2"] = []
      widget_params["set_data"]["col3"] = []
      expect(response.parsed_body.values_at(*widget_params_for_update.keys)).to match_array(widget_params_for_update.values)
      ws = MiqWidgetSet.find(response.parsed_body['id'])
      expect(ws.members.map(&:id)).to eq(widgets.map(&:id))
    end

    it "deletes widget set" do
      api_basic_authorize collection_action_identifier(:widget_sets, :delete, :post)
      widget_set_id = miq_widget_set.id
      group.settings = {"dashboard_order" => [1, widget_set_id]}
      group.save
      post api_widget_set_url(nil, miq_widget_set), :params => gen_request(:delete, widget_params)
      expect(response).to have_http_status(:ok)
      expect(MiqWidgetSet.find_by(:id => widget_set_id)).to be_nil
      group.reload
      expect(group.settings["dashboard_order"]).not_to include(widget_set_id)
    end

    it "forbids action for non-super-admin user" do
      expect_forbidden_request do
        post(api_widget_sets_url)
      end
    end
  end

  context "PUT" do
    it "updates widget set" do
      api_basic_authorize collection_action_identifier(:widget_sets, :edit, :post)
      params_for_put = widget_params.except('name')
      put api_widget_set_url(nil, miq_widget_set), :params => params_for_put

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id'].to_i).to eq(miq_widget_set.id)

      widget_params["set_data"]["col2"] = []
      widget_params["set_data"]["col3"] = []
      expect(response.parsed_body.values_at(*params_for_put.keys)).to match_array(params_for_put.values)
    end

    it "forbids action for non-super-admin user" do
      expect_forbidden_request do
        put(api_widget_set_url(nil, miq_widget_set))
      end
    end
  end

  context "DELETE" do
    it "deletes widget set" do
      api_basic_authorize collection_action_identifier(:widget_sets, :delete, :post)
      widget_set_id = miq_widget_set.id

      delete api_widget_set_url(nil, miq_widget_set)
      expect(response).to have_http_status(:no_content)
      expect(MiqWidgetSet.find_by(:id => widget_set_id)).to be_nil
    end

    it "forbids action for non-super-admin user" do
      expect_forbidden_request do
        delete(api_widget_set_url(nil, miq_widget_set))
      end
    end
  end
end
