describe "Container Templates API" do
  context 'GET /api/container_templates' do
    it 'forbids access to container templates without an appropriate role' do
      api_basic_authorize

      get(api_container_templates_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns container templates with an appropriate role' do
      container_template = FactoryBot.create(:container_template)
      api_basic_authorize(collection_action_identifier(:container_templates, :read, :get))

      get(api_container_templates_url)

      expected = {
        'resources' => [{'href' => api_container_template_url(nil, container_template)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'GET /api/container_templates' do
    let(:container_template) { FactoryBot.create(:container_template) }

    it 'forbids access to a container template without an appropriate role' do
      api_basic_authorize

      get(api_container_template_url(nil, container_template))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the container template with an appropriate role' do
      api_basic_authorize(action_identifier(:container_templates, :read, :resource_actions, :get))

      get(api_container_template_url(nil, container_template))

      expected = {
        'href' => api_container_template_url(nil, container_template)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
