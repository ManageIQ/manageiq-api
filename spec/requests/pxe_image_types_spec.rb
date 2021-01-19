RSpec.describe 'PxeImageTypes API' do
  let!(:image_type) { FactoryBot.create(:pxe_image_type) }

  describe 'GET /api/pxe_image_types' do
    let(:url) { api_pxe_image_types_url }

    it 'lists all pxe image types with an appropriate role' do
      api_basic_authorize collection_action_identifier(:pxe_image_types, :read, :get)
      get(url)
      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'pxe_image_types',
        'resources' => [
          hash_including('href' => api_pxe_image_type_url(nil, image_type))
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

  describe 'GET /api/pxe_image_types/:id' do
    let(:url) { api_pxe_image_type_url(nil, image_type) }

    it 'will show a pxe image type with an appropriate role' do
      api_basic_authorize action_identifier(:pxe_image_types, :read, :resource_actions, :get)
      get(url)
      expect(response.parsed_body).to include('href' => api_pxe_image_type_url(nil, image_type))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/pxe_image_types' do
    it 'forbids creating a pxe image type without an appropriate role' do
      api_basic_authorize
      post(api_pxe_image_types_url, :params => {:action => 'create'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids updating a pxe image type without an appropriate role' do
      api_basic_authorize
      post(api_pxe_image_types_url, :params => {:action => 'edit'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids deleting a pxe image type without an appropriate role' do
      api_basic_authorize
      post(api_pxe_image_types_url, :params => {:action => 'delete'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'creates a pxe image type with an appropriate role' do
      params = {"name" => 'name', "provision_type" => 'host'}
      api_basic_authorize collection_action_identifier(:pxe_image_types, :create)

      post(api_pxe_image_types_url, :params => params)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["results"].first).to include(params)
    end

    it 'updates a pxe image type with an appropriate role' do
      api_basic_authorize collection_action_identifier(:pxe_image_types, :edit)

      post(api_pxe_image_types_url, :params => {:action => 'edit', :id => image_type.id, :provision_type => 'vm'})

      expect(response).to have_http_status(:ok)
      expect(image_type.reload.provision_type).to eq('vm')
    end

    it 'deletes a pxe image type with an appropriate role' do
      api_basic_authorize collection_action_identifier(:pxe_image_types, :delete)

      post(api_pxe_image_types_url, :params => {:action => :delete, :id => image_type.id, :href => api_pxe_image_type_url(nil, image_type)})

      expect(response).to have_http_status(:ok)
      expect(CustomizationTemplate.exists?(image_type.id)).to be false
    end
  end

  describe 'POST /api/pxe_image_types/:id' do
    it 'forbids updating a pxe image type without an appropriate role' do
      api_basic_authorize
      post(api_pxe_image_type_url(nil, image_type), :params => {:action => 'edit', :name => 'name changed'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids deleting a pxe image type without an appropriate role' do
      api_basic_authorize
      post(api_pxe_image_type_url(nil, image_type), :params => {:action => 'delete'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'updates a pxe image type with an appropriate role' do
      api_basic_authorize collection_action_identifier(:pxe_image_types, :edit)

      post(api_pxe_image_type_url(nil, image_type), :params => {:action => 'edit', :name => 'name changed'})

      expect(image_type.reload.name).to eq('name changed')
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('href' => api_pxe_image_type_url(nil, image_type))
    end

    it 'deletes a pxe image type with an appropriate role' do
      api_basic_authorize collection_action_identifier(:pxe_image_types, :delete)

      expect do
        post(api_pxe_image_type_url(nil, image_type), :params => {:action => 'delete'})
      end.to change(PxeImageType, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /api/pxe_image_types/:id' do
    it 'forbids updating a pxe image type without an appropriate role' do
      api_basic_authorize
      patch(api_pxe_image_type_url(nil, image_type), :params => {:name => 'name changed'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'updates a pxe image type with an appropriate role' do
      api_basic_authorize collection_action_identifier(:pxe_image_types, :edit)

      patch(api_pxe_image_type_url(nil, image_type), :params => {:name => 'name changed'})

      expect(image_type.reload.name).to eq('name changed')
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PUT /api/pxe_image_types/:id' do
    it 'forbids updating a pxe image type without an appropriate role' do
      api_basic_authorize
      put(api_pxe_image_type_url(nil, image_type), :params => {:name => 'name changed'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'updates a pxe image type with an appropriate role' do
      api_basic_authorize collection_action_identifier(:pxe_image_types, :edit)

      put(api_pxe_image_type_url(nil, image_type), :params => {:name => 'name changed'})

      expect(image_type.reload.name).to eq('name changed')
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE /api/pxe_image_types/:id' do
    it "deletes a pxe image type with an appropriate role" do
      api_basic_authorize(action_identifier(:pxe_image_types, :delete))
      expect do
        delete(api_pxe_image_type_url(nil, image_type))
      end.to change(PxeImageType, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'forbids deleting a pxe image type without an appropriate role' do
      api_basic_authorize
      delete(api_pxe_image_type_url(nil, image_type))
      expect(response).to have_http_status(:forbidden)
    end
  end
end
