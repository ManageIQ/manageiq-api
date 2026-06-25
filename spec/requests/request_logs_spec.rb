RSpec.describe "Request Logs Subcollection API" do
  # request_logs is authorized via miq_request_show (the per-resource identifier), not the parent
  # collection's miq_request_show_list. subcollection_action_identifier resolves this correctly.
  shared_examples "request_logs subcollection" do |parent_collection, parent_factory, logs_url_helper, log_url_helper|
    let(:request) { FactoryBot.create(parent_factory, :requester => @user) }
    let(:log)     { FactoryBot.create(:request_log, :resource => request) }

    context "listing logs" do
      it "is forbidden without appropriate role" do
        api_basic_authorize

        get send(logs_url_helper, nil, request)

        expect(response).to have_http_status(:forbidden)
      end

      it "returns only logs belonging to the parent request" do
        other_request = FactoryBot.create(parent_factory, :requester => @user)
        log
        other_log = FactoryBot.create(:request_log, :resource => other_request)
        api_basic_authorize subcollection_action_identifier(parent_collection, :request_logs, :read, :get)

        get send(logs_url_helper, nil, request), :params => {:expand => :resources}

        expect(response).to have_http_status(:ok)
        returned_ids = response.parsed_body["resources"].map { |r| r["id"] }
        expect(returned_ids).to include(log.id.to_s)
        expect(returned_ids).not_to include(other_log.id.to_s)
      end

      it "returns all logs for the request" do
        log1 = FactoryBot.create(:request_log, :resource => request, :message => "first")
        log2 = FactoryBot.create(:request_log, :resource => request, :message => "second")
        api_basic_authorize subcollection_action_identifier(parent_collection, :request_logs, :read, :get)

        get send(logs_url_helper, nil, request), :params => {:expand => :resources}

        expect(response).to have_http_status(:ok)
        returned_ids = response.parsed_body["resources"].map { |r| r["id"] }
        expect(returned_ids).to match_array([log1.id.to_s, log2.id.to_s])
      end
    end

    context "showing a single log" do
      it "is forbidden without appropriate role" do
        api_basic_authorize

        get send(log_url_helper, nil, request, log)

        expect(response).to have_http_status(:forbidden)
      end

      it "returns the log" do
        api_basic_authorize subcollection_action_identifier(parent_collection, :request_logs, :read, :get)

        get send(log_url_helper, nil, request, log)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(
          "id"       => log.id.to_s,
          "message"  => log.message,
          "severity" => log.severity
        )
      end
    end
  end

  context "under /requests" do
    include_examples "request_logs subcollection",
                     :requests,
                     :service_template_provision_request,
                     :api_request_request_logs_url,
                     :api_request_request_log_url
  end

  context "under /service_requests" do
    include_examples "request_logs subcollection",
                     :service_requests,
                     :service_template_provision_request,
                     :api_service_request_request_logs_url,
                     :api_service_request_request_log_url
  end

  context "under /automation_requests" do
    include_examples "request_logs subcollection",
                     :automation_requests,
                     :automation_request,
                     :api_automation_request_request_logs_url,
                     :api_automation_request_request_log_url
  end

  context "under /provision_requests" do
    include_examples "request_logs subcollection",
                     :provision_requests,
                     :miq_provision_request,
                     :api_provision_request_request_logs_url,
                     :api_provision_request_request_log_url
  end
end
