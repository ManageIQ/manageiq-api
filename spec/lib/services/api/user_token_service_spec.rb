RSpec.describe Api::UserTokenService do
  describe ".generate_token" do
    before do
      @user = FactoryGirl.create(:user_with_group)
    end

    it "uses default token_ttl" do
      user_token_service = described_class.new
      token = user_token_service.generate_token(@user.userid, 'api')

      expect(user_token_service.token_mgr('api').token_get_info(token)).to include(
        :userid    => @user.userid,
        :token_ttl => Settings.api.token_ttl.to_i_with_method
      )
    end

    it "supports optional token_ttl" do
      user_token_service = described_class.new
      token = user_token_service.generate_token(@user.userid, 'api', 5559)

      expect(user_token_service.token_mgr('api').token_get_info(token)).to include(
        :userid    => @user.userid,
        :token_ttl => 5559
      )
    end
  end
end
