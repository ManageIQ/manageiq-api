RSpec.describe Api::GenericObjectSerializer do
  describe ".serialize" do
    it "does not serialize the properties" do
      generic_object_definition = FactoryGirl.create(
        :generic_object_definition,
        :properties => {
          :attributes => {:foo => "string"}
        }
      )
      generic_object = FactoryGirl.create(
        :generic_object,
        :generic_object_definition => generic_object_definition,
        :property_attributes       => {:foo => "bar"}
      )

      actual = described_class.serialize(generic_object)

      expect(actual).not_to include("properties")
    end
  end
end
