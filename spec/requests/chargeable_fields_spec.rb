describe "Chargeable Field API" do
  context "GET /api/chargeable_fields" do
    before do
      ChargebackRateDetailMeasure.seed
      ChargeableField.seed
    end

    it "does not allow an unauthorized user to list the chargeable fields" do
      api_basic_authorize

      get(api_chargeable_fields_url)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns the chargeable fields" do
      api_basic_authorize(:chargeback)

      get(api_chargeable_fields_url)

      fields = ChargeableField.all.map do |field|
        {"href" => api_chargeable_field_url(nil, field)}
      end

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['resources']).to match_array(fields)
    end
  end

  context "GET /api/api_chargeable_fields/:id" do
    it "returns the api chargeable fields" do
      chargeable_field = FactoryBot.create(:chargeable_field_cpu_allocated)
      api_basic_authorize(:chargeback)

      get(api_chargeable_field_url(nil, chargeable_field))

      expected = chargeable_field.attributes.merge("href" => api_chargeable_field_url(nil, chargeable_field))
      expected['id'] = expected['id'].to_s

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
