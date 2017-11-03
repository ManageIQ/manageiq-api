RSpec.describe Api::UserSerializer do
  describe ".serialize" do
    it "does not serialize the password digest" do
      user = FactoryGirl.create(:user, :password_digest => "$2a$10$FTbGT/y/PQ1HvoOoc1FcyuuTtHzfop/uG/mcEAJLYpzmsUIJcGT7W")

      actual = described_class.serialize(user)

      expect(actual).not_to include("password_digest")
    end
  end
end
