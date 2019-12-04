RSpec.describe "chargebacks API" do
  let(:field) { FactoryBot.create(:chargeable_field) }

  it "can fetch the list of all chargeback rates" do
    chargeback_rate = FactoryBot.create(:chargeback_rate)

    api_basic_authorize collection_action_identifier(:chargebacks, :read, :get)
    get api_chargebacks_url

    expect_result_resources_to_include_hrefs(
      "resources", [api_chargeback_url(nil, chargeback_rate)]
    )
    expect_result_to_match_hash(response.parsed_body, "count" => 1)
    expect(response).to have_http_status(:ok)
  end

  it "can show an individual chargeback rate" do
    chargeback_rate = FactoryBot.create(:chargeback_rate)

    api_basic_authorize action_identifier(:chargebacks, :read, :resource_actions, :get)
    get api_chargeback_url(nil, chargeback_rate)

    expect_result_to_match_hash(
      response.parsed_body,
      "description" => chargeback_rate.description,
      "guid"        => chargeback_rate.guid,
      "id"          => chargeback_rate.id.to_s,
      "href"        => api_chargeback_url(nil, chargeback_rate)
    )
    expect(response).to have_http_status(:ok)
  end

  it "can fetch chargeback rate details" do
    chargeback_rate_detail = FactoryBot.build(:chargeback_rate_detail, :chargeable_field => field)
    chargeback_tier = FactoryBot.create(:chargeback_tier, :chargeback_rate_detail_id => chargeback_rate_detail.id,
                                         :start => 0, :finish => Float::INFINITY, :fixed_rate => 0.0,
                                         :variable_rate => 0.0)
    chargeback_rate_detail.chargeback_tiers = [chargeback_tier]
    chargeback_rate = FactoryBot.create(:chargeback_rate,
                                         :chargeback_rate_details => [chargeback_rate_detail])

    api_basic_authorize
    get(api_chargeback_rates_url(nil, chargeback_rate))

    expect_query_result(:rates, 1, 1)
    expect_result_resources_to_include_hrefs(
      "resources",
      [api_chargeback_rate_url(nil, chargeback_rate, chargeback_rate_detail)]
    )
  end

  it "can fetch an individual chargeback rate detail" do
    chargeback_rate_detail = FactoryBot.build(:chargeback_rate_detail, :description => "rate_1", :chargeable_field => field)
    chargeback_tier = FactoryBot.create(:chargeback_tier, :chargeback_rate_detail_id => chargeback_rate_detail.id,
                                         :start => 0, :finish => Float::INFINITY, :fixed_rate => 0.0,
                                         :variable_rate => 0.0)
    chargeback_rate_detail.chargeback_tiers = [chargeback_tier]
    chargeback_rate = FactoryBot.create(:chargeback_rate,
                                         :chargeback_rate_details => [chargeback_rate_detail])

    api_basic_authorize
    get(api_chargeback_rate_url(nil, chargeback_rate, chargeback_rate_detail))

    expect_result_to_match_hash(
      response.parsed_body,
      "chargeback_rate_id" => chargeback_rate.id.to_s,
      "href"               => api_chargeback_rate_url(nil, chargeback_rate, chargeback_rate_detail),
      "id"                 => chargeback_rate_detail.id.to_s,
      "description"        => "rate_1"
    )
    expect(response).to have_http_status(:ok)
  end

  it "can list of all currencies" do
    currency = FactoryBot.create(:currency)

    api_basic_authorize
    get '/api/currencies'

    expect_result_resources_to_include_hrefs(
      "resources", [api_currency_url(nil, currency)]
    )
    expect_result_to_match_hash(response.parsed_body, "count" => 1)
    expect(response).to have_http_status(:ok)
  end

  it "can show an individual currency" do
    currency = FactoryBot.create(:currency)

    api_basic_authorize
    get "/api/currencies/#{currency.id}"

    expect_result_to_match_hash(
      response.parsed_body,
      "name" => currency.name,
      "id"   => currency.id.to_s,
      "href" => api_currency_url(nil, currency)
    )
    expect(response).to have_http_status(:ok)
  end

  it "can list of all measures" do
    measure = FactoryBot.create(:chargeback_rate_detail_measure)

    api_basic_authorize
    get '/api/measures'

    expect_result_resources_to_include_hrefs(
      "resources", [api_measure_url(nil, measure)]
    )
    expect_result_to_match_hash(response.parsed_body, "count" => 1)
    expect(response).to have_http_status(:ok)
  end

  it "can show an individual measure" do
    measure = FactoryBot.create(:chargeback_rate_detail_measure)

    api_basic_authorize
    get "/api/measures/#{measure.id}"

    expect_result_to_match_hash(
      response.parsed_body,
      "name" => measure.name,
      "id"   => measure.id.to_s,
      "href" => api_measure_url(nil, measure)
    )
    expect(response).to have_http_status(:ok)
  end

  context "with an appropriate role" do
    it "can create a new chargeback rate" do
      api_basic_authorize action_identifier(:chargebacks, :create, :collection_actions)

      expect do
        post(
          api_chargebacks_url,
          :params => {
            :description => "chargeback_0",
            :rate_type   => "Storage"
          }
        )
      end.to change(ChargebackRate, :count).by(1)
      expect_result_to_match_hash(response.parsed_body["results"].first, "description" => "chargeback_0",
                                                                         "rate_type"   => "Storage",
                                                                         "default"     => false)
      expect(response).to have_http_status(:ok)
    end

    it "returns bad request for incomplete chargeback rate" do
      api_basic_authorize action_identifier(:chargebacks, :create, :collection_actions)

      expect do
        post api_chargebacks_url, :params => { :rate_type => "Storage" }
      end.not_to change(ChargebackRate, :count)
      expect_bad_request(/description can't be blank/i)
    end

    it "can edit a chargeback rate through POST" do
      chargeback_rate = FactoryBot.create(:chargeback_rate, :description => "chargeback_0")

      api_basic_authorize action_identifier(:chargebacks, :edit)
      post api_chargeback_url(nil, chargeback_rate), :params => gen_request(:edit, :description => "chargeback_1")

      expect(response.parsed_body["description"]).to eq("chargeback_1")
      expect(response).to have_http_status(:ok)
      expect(chargeback_rate.reload.description).to eq("chargeback_1")
    end

    it "can edit a chargeback rate through PATCH" do
      chargeback_rate = FactoryBot.create(:chargeback_rate, :description => "chargeback_0")

      api_basic_authorize action_identifier(:chargebacks, :edit)
      patch api_chargeback_url(nil, chargeback_rate), :params => [{:action => "edit",
                                                                   :path   => "description",
                                                                   :value  => "chargeback_1"}]

      expect(response.parsed_body["description"]).to eq("chargeback_1")
      expect(response).to have_http_status(:ok)
      expect(chargeback_rate.reload.description).to eq("chargeback_1")
    end

    it "can delete a chargeback rate" do
      chargeback_rate = FactoryBot.create(:chargeback_rate)

      api_basic_authorize action_identifier(:chargebacks, :delete)

      expect do
        delete api_chargeback_url(nil, chargeback_rate)
      end.to change(ChargebackRate, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "can delete a chargeback rate through POST" do
      chargeback_rate = FactoryBot.create(:chargeback_rate)

      api_basic_authorize action_identifier(:chargebacks, :delete)

      expect do
        post api_chargeback_url(nil, chargeback_rate), :params => { :action => "delete" }
      end.to change(ChargebackRate, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end

    it "can create a new chargeback rate detail" do
      api_basic_authorize action_identifier(:rates, :create, :collection_actions)
      chargeback_rate = FactoryBot.create(:chargeback_rate)

      expect do
        post(
          api_rates_url,
          :params => {
            :description         => "rate_0",
            :group               => "fixed",
            :chargeback_rate_id  => chargeback_rate.id,
            :chargeable_field_id => field.id,
            :source              => "used",
            :enabled             => true
          }
        )
      end.to change(ChargebackRateDetail, :count).by(1)
      expect_result_to_match_hash(response.parsed_body["results"].first, "description" => "rate_0", "enabled" => true)
      expect(response).to have_http_status(:ok)
    end

    it "returns bad request for incomplete chargeback rate detail" do
      api_basic_authorize action_identifier(:rates, :create, :collection_actions)

      expect do
        post api_rates_url, :params => { :description => "rate_0", :enabled => true }
      end.not_to change(ChargebackRateDetail, :count)
      expect_bad_request(/Chargeback rate can't be blank/i)
      expect_bad_request(/Chargeable field can't be blank/i)
    end

    it "can edit a chargeback rate detail through POST" do
      chargeback_rate_detail = FactoryBot.build(:chargeback_rate_detail, :description => "rate_0", :chargeable_field => field)
      chargeback_tier = FactoryBot.create(:chargeback_tier, :chargeback_rate_detail_id => chargeback_rate_detail.id,
                                           :start => 0, :finish => Float::INFINITY, :fixed_rate => 0.0,
                                           :variable_rate => 0.0)
      chargeback_rate_detail.chargeback_tiers = [chargeback_tier]
      chargeback_rate_detail.save

      api_basic_authorize action_identifier(:rates, :edit)
      post api_rate_url(nil, chargeback_rate_detail), :params => gen_request(:edit, :description => "rate_1")

      expect(response.parsed_body["description"]).to eq("rate_1")
      expect(response).to have_http_status(:ok)
      expect(chargeback_rate_detail.reload.description).to eq("rate_1")
    end

    it "can edit a chargeback rate detail through PATCH" do
      chargeback_rate_detail = FactoryBot.build(:chargeback_rate_detail, :description => "rate_0", :chargeable_field => field)
      chargeback_tier = FactoryBot.create(:chargeback_tier, :chargeback_rate_detail_id => chargeback_rate_detail.id,
                                           :start => 0, :finish => Float::INFINITY, :fixed_rate => 0.0,
                                           :variable_rate => 0.0)
      chargeback_rate_detail.chargeback_tiers = [chargeback_tier]
      chargeback_rate_detail.save

      api_basic_authorize action_identifier(:rates, :edit)
      patch api_rate_url(nil, chargeback_rate_detail), :params => [{:action => "edit", :path => "description", :value => "rate_1"}]

      expect(response.parsed_body["description"]).to eq("rate_1")
      expect(response).to have_http_status(:ok)
      expect(chargeback_rate_detail.reload.description).to eq("rate_1")
    end

    it "can delete a chargeback rate detail" do
      chargeback_rate_detail = FactoryBot.build(:chargeback_rate_detail, :chargeable_field => field)
      chargeback_tier = FactoryBot.create(:chargeback_tier, :chargeback_rate_detail_id => chargeback_rate_detail.id,
                                           :start => 0, :finish => Float::INFINITY, :fixed_rate => 0.0,
                                           :variable_rate => 0.0)
      chargeback_rate_detail.chargeback_tiers = [chargeback_tier]
      chargeback_rate_detail.save

      api_basic_authorize action_identifier(:rates, :delete)

      expect do
        delete api_rate_url(nil, chargeback_rate_detail)
      end.to change(ChargebackRateDetail, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "can delete a chargeback rate detail through POST" do
      chargeback_rate_detail = FactoryBot.build(:chargeback_rate_detail, :chargeable_field => field)
      chargeback_tier = FactoryBot.create(:chargeback_tier, :chargeback_rate_detail_id => chargeback_rate_detail.id,
                                           :start => 0, :finish => Float::INFINITY, :fixed_rate => 0.0,
                                           :variable_rate => 0.0)
      chargeback_rate_detail.chargeback_tiers = [chargeback_tier]
      chargeback_rate_detail.save

      api_basic_authorize action_identifier(:rates, :delete)

      expect do
        post api_rate_url(nil, chargeback_rate_detail), :params => { :action => "delete" }
      end.to change(ChargebackRateDetail, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end
  end

  context "without an appropriate role" do
    it "cannot create a chargeback rate" do
      api_basic_authorize

      expect { post api_chargebacks_url, :params => { :description => "chargeback_0" } }.not_to change(ChargebackRate, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it "cannot edit a chargeback rate" do
      chargeback_rate = FactoryBot.create(:chargeback_rate, :description => "chargeback_0")

      api_basic_authorize

      expect do
        post api_chargeback_url(nil, chargeback_rate), :params => gen_request(:edit, :description => "chargeback_1")
      end.not_to change { chargeback_rate.reload.description }
      expect(response).to have_http_status(:forbidden)
    end

    it "cannot delete a chargeback rate" do
      chargeback_rate = FactoryBot.create(:chargeback_rate)

      api_basic_authorize

      expect do
        delete api_chargeback_url(nil, chargeback_rate)
      end.not_to change(ChargebackRate, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it "cannot create a chargeback rate detail" do
      api_basic_authorize

      expect { post api_rates_url, :params => { :description => "rate_0", :enabled => true } }.not_to change(ChargebackRateDetail, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it "cannot edit a chargeback rate detail" do
      chargeback_rate_detail = FactoryBot.build(:chargeback_rate_detail, :description => "rate_1", :chargeable_field => field)
      chargeback_tier = FactoryBot.create(:chargeback_tier, :chargeback_rate_detail_id => chargeback_rate_detail.id,
                                           :start => 0, :finish => Float::INFINITY, :fixed_rate => 0.0,
                                           :variable_rate => 0.0)
      chargeback_rate_detail.chargeback_tiers = [chargeback_tier]
      chargeback_rate_detail.save

      api_basic_authorize

      expect do
        post api_rate_url(nil, chargeback_rate_detail), :params => gen_request(:edit, :description => "rate_2")
      end.not_to change { chargeback_rate_detail.reload.description }
      expect(response).to have_http_status(:forbidden)
    end

    it "cannot delete a chargeback rate detail" do
      chargeback_rate_detail = FactoryBot.build(:chargeback_rate_detail, :chargeable_field => field)
      chargeback_tier = FactoryBot.create(:chargeback_tier, :chargeback_rate_detail_id => chargeback_rate_detail.id,
                                           :start => 0, :finish => Float::INFINITY, :fixed_rate => 0.0,
                                           :variable_rate => 0.0)
      chargeback_rate_detail.chargeback_tiers = [chargeback_tier]
      chargeback_rate_detail.save

      api_basic_authorize

      expect do
        delete api_rate_url(nil, chargeback_rate_detail)
      end.not_to change(ChargebackRateDetail, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
