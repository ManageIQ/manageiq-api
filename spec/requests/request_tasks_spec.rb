RSpec.describe "Request Tasks API" do
  context "Resource#cancel" do
    let(:resource_1_response) { {"success" => false, "message" => "Cancel operation is not supported for MiqRequestTask"} }
    let(:resource_2_response) { {"success" => false, "message" => "Cancel operation is not supported for MiqRequestTask"} }
    include_context "Resource#cancel", "request_task", :miq_request_task
  end
end
