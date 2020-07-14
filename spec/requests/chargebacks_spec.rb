RSpec.describe "chargebacks API" do
  let(:field) { FactoryBot.create(:chargeable_field, :chargeback_rate_detail_measure_id => measure.id) }
  let(:measure) { FactoryBot.create(:chargeback_rate_detail_measure) }
  let(:chargeback_rate_detail) { FactoryBot.build(:chargeback_rate_detail, :description => "rate_0", :detail_measure => measure, :chargeable_field => field) }
  let(:chargeback_tier) do
    FactoryBot.create(:chargeback_tier, :chargeback_rate_detail_id => chargeback_rate_detail.id, :start => 0, :finish => Float::INFINITY, :fixed_rate => 0.0, :variable_rate => 0.0)
  end

  def convert_to_response_hash(resource)
    resource.attributes.map do |attribute_name, attribute_value|
      attribute_value = attribute_value.to_s if attribute_value.present? && (attribute_name.include?("id") || attribute_value == Float::INFINITY)
      attribute_value = attribute_value.strftime("%FT%TZ") if attribute_value.kind_of?(ActiveSupport::TimeWithZone)
      {attribute_name => attribute_value}
    end.reduce(:merge)
  end

  let(:expected_tier)             { convert_to_response_hash(chargeback_tier) }
  let(:expected_chargeable_field) { convert_to_response_hash(chargeback_rate_detail.chargeable_field) }
  let(:expected_chargeback_rate)  { convert_to_response_hash(chargeback_rate_detail.chargeback_rate) }
  let(:expected_currency)         { convert_to_response_hash(chargeback_rate_detail.detail_currency) }
  let(:expected_measure)          { convert_to_response_hash(chargeback_rate_detail.detail_measure) }

  it "can fetch the list of all rates" do
    chargeback_rate_detail.chargeback_tiers = [chargeback_tier]
    chargeback_rate_detail.save

    api_basic_authorize collection_action_identifier(:rates, :read, :get)
    request_attributes = {:expand => 'resources', :attributes => 'chargeback_tiers,chargeback_rate,detail_measure,detail_currency,chargeable_field'}

    get api_rates_url, :params => request_attributes

    expect(response.parsed_body['resources'][0]).to include("chargeback_tiers" => [expected_tier],
                                                            "chargeable_field" => expected_chargeable_field,
                                                            "chargeback_rate"  => expected_chargeback_rate,
                                                            "detail_currency"  => expected_currency,
                                                            "detail_measure"   => expected_measure)

    expect_result_to_match_hash(response.parsed_body, "count" => 1)
    expect(response).to have_http_status(:ok)
  end

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

  let(:category)           { FactoryBot.create(:classification, :description => "Environment", :name => "environment", :single_value => true, :show => true) }
  let(:tag_classification) { FactoryBot.create(:classification, :name => "prod", :description => "Production", :parent_id => category.id) }

  let(:expected_tag) {
    {
      "tag" => {
        "assigment_type_description" => "Tagged VMs and Instances",
        "href"                       => api_tag_url(nil, tag_classification.tag),
        "name"                       => "prod",
        "description"                => "Production",
        "category"                   => "environment",
        "assignment_prefix"          => "vm"
      }
    }
  }

  it "can show an individual chargeback rate" do
    chargeback_rate = FactoryBot.create(:chargeback_rate)

    temp = {:cb_rate => chargeback_rate, :tag => [tag_classification, "vm"]}
    ChargebackRate.set_assignments(:compute, [temp])

    api_basic_authorize action_identifier(:chargebacks, :read, :resource_actions, :get)
    get api_chargeback_url(nil, chargeback_rate), :params => {'attributes' => 'assigned_to'}

    expect_result_to_match_hash(
      response.parsed_body,
      "description" => chargeback_rate.description,
      "guid"        => chargeback_rate.guid,
      "id"          => chargeback_rate.id.to_s,
      "href"        => api_chargeback_url(nil, chargeback_rate),
      "assigned_to" => [expected_tag]
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
  end

  context "rate assignment" do
    it_behaves_like "perform rate assign/unassign action", "Compute", :ext_management_system, :providers
    it_behaves_like "perform rate assign/unassign action", "Compute", :tenant, :tenants
    it_behaves_like "perform rate assign/unassign action", "Compute", :ems_cluster, :clusters
    it_behaves_like "perform rate assign/unassign action", "Compute", :miq_enterprise, :enterprises
    it_behaves_like "perform rate assign/unassign action", "Compute", :custom_attribute, :custom_attributes
    it_behaves_like "perform rate assign/unassign action", "Compute", :tag, :tags, "vm"
    it_behaves_like "perform rate assign/unassign action", "Compute", :tag, :tags, "container_image"

    it_behaves_like "perform rate assign/unassign action", "Storage", :miq_enterprise, :enterprises
    it_behaves_like "perform rate assign/unassign action", "Storage", :storage, :data_stores
    it_behaves_like "perform rate assign/unassign action", "Storage", :tag, :tags, "storage"
    it_behaves_like "perform rate assign/unassign action", "Storage", :tenant, :tenants
  end
end
