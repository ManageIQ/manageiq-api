RSpec.describe "guest devices API" do
  describe "display guest device details" do
    context "with the user authorized" do
      it "responds with device properties" do
        device = FactoryGirl.create(:guest_device,
                                    :device_name => "Broadcom 2-port 1GbE NIC Card",
                                    :device_type => "ethernet",
                                    :location    => "Bay 7")

        api_basic_authorize action_identifier(:guest_devices, :read, :resource_actions, :get)

        run_get(api_guest_device_url(nil, device))

        expect_single_resource_query("device_name" => "Broadcom 2-port 1GbE NIC Card",
                                     "device_type" => "ethernet",
                                     "location"    => "Bay 7")
      end
    end

    context "with the user unauthorized" do
      it "responds with a forbidden status" do
        device = FactoryGirl.create(:guest_device)

        api_basic_authorize

        run_get(api_guest_device_url(nil, device))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
