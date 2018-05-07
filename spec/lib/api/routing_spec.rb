RSpec.describe Api::Routing do
  describe ".inflections_for_named_route_helpers" do
    it "returns plural and singular for regular names" do
      collection_name = :accounts # first collection_name on the api.yml

      expected_plural    = "accounts"
      expected_singular  = "account"

      actual = Api::Routing.inflections_for_named_route_helpers(collection_name.to_s)
      expect(actual).to eq([expected_plural, expected_singular])
    end

    it "returns a modified singular for names that singular == plural" do
      collection_name    = :chassis
      expected_plural    = "chassis"
      expected_singular  = "one_chassis"

      actual = Api::Routing.inflections_for_named_route_helpers(collection_name.to_s)

      # If the inflection for "chassis" is set on the core this test makes sense
      # The inflector will retrieve the same value for plural and singular
      if collection_name.to_s.pluralize == collection_name.to_s.singularize
        expect(actual).to eq([expected_plural, expected_singular])
      else
        expect(actual).to_not eq([expected_plural, expected_singular])
      end
    end
  end
end
