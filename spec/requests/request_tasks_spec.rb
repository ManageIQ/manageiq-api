RSpec.describe "Request Tasks API" do
  context "Resource#cancel" do
    include_context "Resource#cancel", "request_task", :miq_request_task, false
  end
end
