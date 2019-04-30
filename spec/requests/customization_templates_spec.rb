RSpec.describe 'CustomizationTemplates API' do
  let!(:template) { FactoryBot.create(:customization_template) }

  describe 'GET /api/customization_templates' do
    let(:url) { api_customization_templates_url }

    it 'lists all customization templates images with an appropriate role' do
      api_basic_authorize collection_action_identifier(:customization_templates, :read, :get)
      get(url)
      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'customization_templates',
        'resources' => [
          hash_including('href' => api_customization_template_url(nil, template))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/customization_templates/:id' do
    let(:url) { api_customization_template_url(nil, template) }

    it 'will show a customization template with an appropriate role' do
      api_basic_authorize action_identifier(:customization_templates, :read, :resource_actions, :get)
      get(url)
      expect(response.parsed_body).to include('href' => api_customization_template_url(nil, template))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
