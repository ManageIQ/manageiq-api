describe "Orchestration Stacks API" do
  context 'GET /api/orchestration_stacks' do
    it 'forbids access to orchestration_stacks without an appropriate role' do
      api_basic_authorize

      get(api_orchestration_stacks_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns orchestration_stacks with an appropriate role' do
      orchestration_stack = FactoryBot.create(:orchestration_stack)
      api_basic_authorize(collection_action_identifier(:orchestration_stacks, :read, :get))

      get(api_orchestration_stacks_url)

      expected = {
        'resources' => [{'href' => api_orchestration_stack_url(nil, orchestration_stack)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'GET /api/orchestration_stacks' do
    let(:orchestration_stack) { FactoryBot.create(:orchestration_stack) }

    it 'forbids access to a orchestration_stack without an appropriate role' do
      api_basic_authorize

      get(api_orchestration_stack_url(nil, orchestration_stack))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the orchestration_stack with an appropriate role' do
      api_basic_authorize(action_identifier(:orchestration_stacks, :read, :resource_actions, :get))

      get(api_orchestration_stack_url(nil, orchestration_stack))

      expected = {
        'href' => api_orchestration_stack_url(nil, orchestration_stack)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
