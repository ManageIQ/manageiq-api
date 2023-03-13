describe "WorkflowInstances API" do
  context "GET /api/workflow_instances" do
    context "without an appropriate role" do
      before { api_basic_authorize }

      it "returns forbidden" do
        FactoryBot.create(:workflow_instance)

        get(api_workflow_instances_url)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with appropriate role" do
      before { api_basic_authorize(collection_action_identifier(:workflow_instances, :read, :get)) }

      it "returns all Workflow Instances" do
        workflow_instance = FactoryBot.create(:workflow_instance)

        get(api_workflow_instances_url)

        expected = {
          "name"      => "workflow_instances",
          "resources" => [{"href" => api_workflow_instance_url(nil, workflow_instance)}]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end

  context "GET /api/workflow_instances/:id" do
    context "without an appropriate role" do
      before { api_basic_authorize }

      it "returns forbidden" do
        workflow_instance = FactoryBot.create(:workflow_instance)

        get(api_workflow_instance_url(nil, workflow_instance))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with appropriate role" do
      before { api_basic_authorize(action_identifier(:workflow_instances, :read, :resource_actions, :get)) }

      it "returns a single Workflow" do
        workflow_instance = FactoryBot.create(:workflow_instance)

        get(api_workflow_instance_url(nil, workflow_instance))

        expected = {
          "id"               => workflow_instance.id.to_s,
          "context"          => workflow_instance.context,
          "credentials"      => workflow_instance.credentials,
          "workflow_content" => workflow_instance.workflow_content,
          "href"             => api_workflow_instance_url(nil, workflow_instance)
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end
end
