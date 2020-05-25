RSpec.describe "chargebacks API" do
  let(:field) { FactoryBot.create(:chargeable_field) }

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
