RSpec.describe "firmwares API" do
  describe "display firmware details" do
    context "with a valid role" do
      it "shows its properties" do
        fw = FactoryGirl.create(:firmware,
                                :name    => "UEFI",
                                :version => "D7E152CUS-2.11")

        api_basic_authorize action_identifier(:firmwares, :read, :resource_actions, :get)

        get(api_firmware_url(nil, fw))

        expect_single_resource_query("name"    => "UEFI",
                                     "version" => "D7E152CUS-2.11")
      end
    end

    context "with an invalid role" do
      it "fails to show its properties" do
        fw = FactoryGirl.create(:firmware)

        api_basic_authorize

        get(api_firmware_url(nil, fw))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
