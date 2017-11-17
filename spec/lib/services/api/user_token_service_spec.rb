RSpec.describe Api::UserTokenService do
  describe ".generate_token" do
    before do
      @user = FactoryGirl.create(:user_with_group)
    end

    let(:user_token_service) { described_class.new }
    let(:token) { user_token_service.generate_token(@user.userid, 'api', token_ttl: token_ttl) }
    let(:token_info) { user_token_service.token_mgr('api').token_get_info(token) }

    context "without token_ttl set" do
      let(:token_ttl) { nil }

      it "uses the default from settings" do
        expect(token_info).to include(:userid => @user.userid, :token_ttl => Settings.api.token_ttl.to_i_with_method)
      end
    end

    context "with token_ttl set" do
      let(:token_ttl) { 5599 }

      it "uses the optional token_ttl specified" do
        expect(token_info).to include(:userid => @user.userid, :token_ttl => 5599)
      end
    end
  end
end
