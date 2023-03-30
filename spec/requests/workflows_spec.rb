describe "Workflows API" do
  context "GET /api/workflows" do
    it "returns all Workflows" do
      workflow = FactoryBot.create(:workflow)
      api_basic_authorize(collection_action_identifier(:workflows, :read, :get))

      get(api_workflows_url)

      expected = {
        "name"      => "workflows",
        "resources" => [{"href" => api_workflow_url(nil, workflow)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "GET /api/workflows/:id" do
    it "returns a single Workflow" do
      workflow = FactoryBot.create(:workflow)
      api_basic_authorize(action_identifier(:workflows, :read, :resource_actions, :get))

      get(api_workflow_url(nil, workflow))

      expected = {
        "name" => workflow.name,
        "href" => api_workflow_url(nil, workflow)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
