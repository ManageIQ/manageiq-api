RSpec.describe Api::BaseSerializer do
  describe ".serialize" do
    it "serializes the model" do
      Timecop.freeze("2017-01-01 00:00:00 UTC") do
        user = FactoryGirl.create(:user, :name => "Alice")

        actual = described_class.serialize(user)

        expected = {
          "id"         => user.id.to_s,
          "name"       => "Alice",
          "created_on" => "2017-01-01T00:00:00Z",
          "updated_on" => "2017-01-01T00:00:00Z"
        }
        expect(actual).to include(expected)
        expect(actual).not_to include("password_digest")
      end
    end

    specify "additional attributes can be requested" do
      vm = FactoryGirl.create(:vm, :vendor => "vmware")

      actual = described_class.serialize(vm, :extra => ["vendor_display"])

      expect(actual).to include("vendor_display" => "VMware")
    end
  end
end
