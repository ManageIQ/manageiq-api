RSpec.describe "chargebacks API" do
  let(:field) { FactoryBot.create(:chargeable_field) }
  let(:currency) { FactoryBot.create(:currency) }
  let(:chargeback_tier_1) { {'start' => 0.0, 'finish' => 1.0, 'fixed_rate' => 1.0, 'variable_rate' => 0.0} }
  let(:chargeback_tier_2) { {'start' => 1.0, 'finish' => 'infinity', 'fixed_rate' => 1.0, 'variable_rate' => 0.0} }

  let(:parameter_tiers) do
    [chargeback_tier_1, chargeback_tier_2].sort_by { |x| x['start'] }
  end

  let(:chargeable_field) { FactoryBot.create(:chargeable_field) }

  it "can create a new chargeback rate detail" do
    api_basic_authorize action_identifier(:rates, :create, :collection_actions)
    chargeback_rate = FactoryBot.create(:chargeback_rate)

    parameters_relations = [
      {:detail_currency  => {:id => currency.id},
       :chargeback_tiers => parameter_tiers,
       :chargeable_field => {:id => chargeable_field.id},
       :chargeback_rate  => {:id => chargeback_rate.id}},
      {:detail_currency  => {:href => api_currency_url(nil, currency)},
       :chargeback_tiers => parameter_tiers,
       :chargeable_field => {:href => api_chargeable_field_url(nil, chargeable_field)},
       :chargeback_rate  => {:href => api_chargeback_url(nil, chargeback_rate)}}
    ]

    parameters_relations.each_with_index do |relations, index|
      expect do
        chargeback_params = {
          :description      => "rate_#{index}",
          :group            => "fixed",
          :chargeback_rate  => relations[:chargeback_rate],
          :chargeable_field => relations[:chargeable_field],
          :detail_currency  => relations[:detail_currency],
          :chargeback_tiers => parameter_tiers,
          :source           => "used",
          :enabled          => true
        }
        post(api_rates_url, :params => chargeback_params)
      end.to change(ChargebackRateDetail, :count).by(1)

      expect_result_to_match_hash(response.parsed_body["results"].first, "description"                        => "rate_#{index}",
                                                                         "enabled"                            => true,
                                                                         "chargeback_rate_detail_currency_id" => currency.id.to_s,
                                                                         "chargeable_field_id"                => chargeable_field.id.to_s,
                                                                         "chargeback_rate_id"                 => chargeback_rate.id.to_s)

      tiers = ChargebackRateDetail.find(response.parsed_body["results"][0]['id']).chargeback_tiers.sort_by(&:start)
      tiers.zip(parameter_tiers).each do |tier, tier_parameters_original|
        tier_parameters = tier_parameters_original.dup

        tier_attributes = tier.attributes.except('id')
        tier_parameters['chargeback_rate_detail_id'] = response.parsed_body["results"][0]['id'].to_i
        tier_parameters['finish'] = Float::INFINITY if tier_parameters['finish'] == 'infinity'

        expect(tier_attributes).to eq(tier_parameters)
      end

      expect(response).to have_http_status(:ok)
    end
  end

  let(:currency_2) { FactoryBot.create(:currency) }

  it "can edit a chargeback rate detail through POST" do
    chargeback_rate = FactoryBot.create(:chargeback_rate)
    chargeback_rate_detail = FactoryBot.build(:chargeback_rate_detail, :description => "rate_0", :chargeable_field => field)
    chargeback_tier = FactoryBot.create(:chargeback_tier, :chargeback_rate_detail_id => chargeback_rate_detail.id,
                                        :start => 0, :finish => Float::INFINITY, :fixed_rate => 0.0,
                                        :variable_rate => 0.0)
    chargeback_rate_detail.chargeback_tiers = [chargeback_tier]
    chargeback_rate_detail.save

    parameters_relations = [
      {:detail_currency  => {:id=> currency_2.id},
       :chargeback_tiers => parameter_tiers,
       :chargeable_field => {:id => chargeable_field.id},
       :chargeback_rate  => {:id => chargeback_rate.id}},
      {:detail_currency  => {:href => api_currency_url(nil, currency_2)},
       :chargeback_tiers => parameter_tiers,
       :chargeable_field => {:href => api_chargeable_field_url(nil, chargeable_field)},
       :chargeback_rate  => {:href => api_chargeback_url(nil, chargeback_rate)}}
    ]

    parameters_relations.each do |relations|
      api_basic_authorize action_identifier(:rates, :edit)
      relations[:description] = "rate_1"
      post api_rate_url(nil, chargeback_rate_detail), :params => gen_request(:edit, relations)

      expect_result_to_match_hash(response.parsed_body, "description"                        => "rate_1",
                                                        "chargeback_rate_detail_currency_id" => currency_2.id.to_s,
                                                        "chargeable_field_id"                => chargeable_field.id.to_s,
                                                        "chargeback_rate_id"                 => chargeback_rate.id.to_s)

      expect(response).to have_http_status(:ok)
      expect(chargeback_rate_detail.reload.description).to eq("rate_1")

      tiers = chargeback_rate_detail.reload.chargeback_tiers.sort_by(&:start)
      tiers.zip(parameter_tiers).each do |tier, tier_parameters_original|
        tier_parameters = tier_parameters_original.dup

        tier_attributes = tier.attributes.except('id')
        tier_parameters['chargeback_rate_detail_id'] = response.parsed_body['id'].to_i
        tier_parameters['finish'] = Float::INFINITY if tier_parameters['finish'] == 'infinity'

        expect(tier_attributes).to eq(tier_parameters)
      end
    end
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

  it "returns bad request for incomplete chargeback rate detail" do
    api_basic_authorize action_identifier(:rates, :create, :collection_actions)

    expect do
      post api_rates_url, :params => {:description => "rate_0", :enabled => true, :chargeback_tiers => parameter_tiers}
    end.not_to change(ChargebackRateDetail, :count)
    expect_bad_request(/Chargeback rate can't be blank/i)
    expect_bad_request(/Chargeable field can't be blank/i)
  end

  it "returns bad request when tiers are missing" do
    api_basic_authorize action_identifier(:rates, :create, :collection_actions)

    expect do
      post api_rates_url, :params => {:description => "rate_0", :enabled => true}
    end.not_to change(ChargebackRateDetail, :count)

    expect_bad_request(/chargeback_tiers needs to be specified/i)
  end

  let(:invalid_tier) { {'start' => 3, 'finish' => 2, 'fixed_rate' => 1.0, 'variable_rate' => 0.0} }

  it "returns bad request when tier is not valid" do
    api_basic_authorize action_identifier(:rates, :create, :collection_actions)

    expect do
      post api_rates_url, :params => {:description => "rate_0", :enabled => true, :chargeback_tiers => [invalid_tier]}
    end.not_to change(ChargebackRateDetail, :count)

    expect_bad_request(/ChargebackTier: Finish value must be greater than start value. \(Tier is not valid\)/i)
  end

  it "returns bad request when tiers are not valid" do
    api_basic_authorize action_identifier(:rates, :create, :collection_actions)

    expect do
      post api_rates_url, :params => {:description => "rate_0", :enabled => true, :chargeback_tiers => parameter_tiers.last(1)}
    end.not_to change(ChargebackRateDetail, :count)

    expect_bad_request(/must start at zero and not contain any gaps between start and prior end value. \(Tiers are not valid\)/i)
  end

  let(:invalid_rate_parameters) { [{'start' => 0.0, 'finish' => nil, 'fixed_rate' => 1.0, 'variable_rate' => 0.0}] }

  it "returns bad request when some attributes are missing" do
    api_basic_authorize action_identifier(:rates, :create, :collection_actions)

    expect do
      post api_rates_url, :params => {:description => "rate_0", :enabled => true, :chargeback_tiers => invalid_rate_parameters}
    end.not_to change(ChargebackRateDetail, :count)

    expect_bad_request(/Attributes start and finish have to be specified for chargeback tier./i)
  end

  it "returns bad request when id or href of relation is missing" do
    api_basic_authorize action_identifier(:rates, :create, :collection_actions)

    expect do
      post api_rates_url, :params => {:description => "rate_0", :enabled => true, :chargeback_tiers => parameter_tiers, :detail_currency => {:symbol => 'CZK'}}
    end.not_to change(ChargebackRateDetail, :count)

    expect_bad_request(/Missing currency identifier href or id/i)
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
      post api_rate_url(nil, chargeback_rate_detail), :params => {:action => "delete"}
    end.to change(ChargebackRateDetail, :count).by(-1)
    expect(response).to have_http_status(:ok)
  end

  it "cannot create a chargeback rate detail" do
    api_basic_authorize

    expect { post api_rates_url, :params => {:description => "rate_0", :enabled => true} }.not_to change(ChargebackRateDetail, :count)
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
    end.not_to change(nil, nil) { chargeback_rate_detail.reload.description }

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
