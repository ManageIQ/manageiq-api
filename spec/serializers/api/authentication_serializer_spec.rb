RSpec.describe Api::AuthenticationSerializer do
  describe ".serialize" do
    it "does not serialize the password" do
      authentication = FactoryGirl.create(:authentication, :password => "alicepassword")

      actual = described_class.serialize(authentication)

      expect(actual).not_to include("password")
    end
  end
end
