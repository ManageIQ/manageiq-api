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

  describe 'POST /api/customization_templates' do
    it 'forbids creating a customization template without an appropriate role' do
      api_basic_authorize
      post(api_customization_templates_url, :params => {:action => 'create'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids updating a customization template without an appropriate role' do
      api_basic_authorize
      post(api_customization_templates_url, :params => {:action => 'edit'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids deleting a customization template without an appropriate role' do
      api_basic_authorize
      post(api_customization_templates_url, :params => {:action => 'delete'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'creates a customization template with an appropriate role' do
      pxe_image_type = FactoryBot.create(:pxe_image_type)
      params = {
        "name"              => 'name',
        "description"       => 'description',
        "script"            => 'test',
        "type"              => 'CustomizationTemplateKickstart',
        "pxe_image_type_id" => pxe_image_type.id.to_s
      }
      api_basic_authorize collection_action_identifier(:customization_templates, :create)

      post(api_customization_templates_url, :params => params)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["results"].first).to include(params)
    end

    it 'updates a customization template with an appropriate role' do
      api_basic_authorize collection_action_identifier(:customization_templates, :edit)

      post(api_customization_templates_url, :params => gen_request(:edit, 'id' => template.id, 'description' => 'description updated'))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["results"].first).to include('href' => api_customization_template_url(nil, template))
      expect(template.reload.description).to eq('description updated')
    end

    it 'deletes a customization template with an appropriate role' do
      api_basic_authorize collection_action_identifier(:customization_templates, :delete)

      post(api_customization_templates_url, :params => gen_request(:delete, 'id' => template.id, 'href' => api_customization_template_url(nil, template)))

      expect(response).to have_http_status(:ok)
      expect(CustomizationTemplate.exists?(template.id)).to be false
    end
  end

  describe 'POST /api/customization_templates/:id' do
    it 'forbids updating a customization template without an appropriate role' do
      api_basic_authorize
      post(api_customization_template_url(nil, template), :params => {:action => 'edit', :description => 'description updated'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids deleting a customization template without an appropriate role' do
      api_basic_authorize
      post(api_customization_template_url(nil, template), :params => {:action => 'delete'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'updates a customization template with an appropriate role' do
      api_basic_authorize collection_action_identifier(:customization_templates, :edit)

      post(api_customization_template_url(nil, template), :params => {:action => 'edit', :description => 'description updated'})

      expect(template.reload.description).to eq('description updated')
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('href' => api_customization_template_url(nil, template))
    end

    it 'deletes a customization template with an appropriate role' do
      api_basic_authorize collection_action_identifier(:customization_templates, :delete)

      expect do
        post(api_customization_template_url(nil, template), :params => {:action => 'delete'})
      end.to change(CustomizationTemplate, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PUT /api/customization_templates/:id' do
    it 'updates a customization template with an appropriate role' do
      api_basic_authorize(action_identifier(:customization_templates, :edit))
      put(api_customization_template_url(nil, template), :params => {:description => 'description updated'})
      expect(response).to have_http_status(:ok)
      expect(template.reload.description).to eq('description updated')
    end

    it 'forbids updating a customization template without an appropriate role' do
      api_basic_authorize
      put(api_customization_template_url(nil, template), :params => {:description => 'description updated'})
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PATCH /api/customization_templates/:id' do
    it 'updates a customization template with an appropriate role' do
      api_basic_authorize(action_identifier(:customization_templates, :edit))
      patch(api_customization_template_url(nil, template), :params => {:description => 'description updated'})
      expect(response).to have_http_status(:ok)
      expect(template.reload.description).to eq('description updated')
    end

    it 'forbids updating a customization template without an appropriate role' do
      api_basic_authorize
      patch(api_customization_template_url(nil, template), :params => {:description => 'description updated'})
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/customization_templates/:id' do
    it "deletes a customization template with an appropriate role" do
      api_basic_authorize(action_identifier(:customization_templates, :delete))
      delete(api_customization_template_url(nil, template))
      expect(response).to have_http_status(:no_content)
    end

    it 'forbids deleting a customization template without an appropriate role' do
      api_basic_authorize
      delete(api_customization_template_url(nil, template))
      expect(response).to have_http_status(:forbidden)
    end
  end
end
