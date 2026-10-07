RSpec.describe "Request Logs API" do
  let(:template) { FactoryBot.create(:service_template) }

  let(:request) do
    FactoryBot.create(:service_template_provision_request,
                       :requester   => @user,
                       :source_id   => template.id,
                       :source_type => template.class.name)
  end

  context "Logs subcollection" do

    it "is forbidden without appropriate role" do
      api_basic_authorize

      get("#{api_request_url(nil, request)}/request_logs")

      expect(response).to have_http_status(:forbidden)
    end

    it "returns request logs for a request" do
      FactoryBot.create(:request_log, :resource => request, :severity => "INFO",  :message => "Request created")
      FactoryBot.create(:request_log, :resource => request, :severity => "INFO",  :message => "Request processed")
      api_basic_authorize subcollection_action_identifier(:requests, :request_logs, :read, :get)

      get("#{api_request_url(nil, request)}/request_logs")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "name"     => "request_logs",
        "count"    => 2,
        "subcount" => 2
      )
    end

    it "does not return logs from another request" do
      other_request = FactoryBot.create(:service_template_provision_request,
                                         :requester   => @user,
                                         :source_id   => template.id,
                                         :source_type => template.class.name)
      FactoryBot.create(:request_log, :resource => other_request, :message => "Other request log")
      api_basic_authorize subcollection_action_identifier(:requests, :request_logs, :read, :get)

      get("#{api_request_url(nil, request)}/request_logs")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["resources"]).to be_empty
      expect(response.parsed_body["subcount"]).to eq(0)

    end

    it "returns the correct attributes" do
      log = FactoryBot.create(:request_log, :resource => request, :severity => "WARN", :message => "Something happened")
      api_basic_authorize subcollection_action_identifier(:requests, :request_logs, :read, :get)

      get("#{api_request_url(nil, request)}/request_logs/#{log.id}")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "id"       => log.id.to_s,
        "severity" => "WARN",
        "message"  => "Something happened"
      )
    end
  end
end