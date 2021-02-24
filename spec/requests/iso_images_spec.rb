RSpec.describe 'IsoImages API' do
  let!(:iso_image) { FactoryBot.create(:iso_image) }

  describe 'GET /api/iso_images' do
    let(:url) { api_iso_images_url }

    it 'lists all iso images with an appropriate role' do
      api_basic_authorize collection_action_identifier(:iso_images, :read, :get)
      get(url)
      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'iso_images',
        'resources' => [
          hash_including('href' => api_iso_image_url(nil, iso_image))
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

  describe 'GET /api/iso_images/:id' do
    let(:url) { api_iso_image_url(nil, iso_image) }

    it 'will show an iso image with an appropriate role' do
      api_basic_authorize action_identifier(:iso_images, :read, :resource_actions, :get)
      get(url)
      expect(response.parsed_body).to include('href' => api_iso_image_url(nil, iso_image))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/iso_images' do
    it 'forbids updating an iso image without an appropriate role' do
      api_basic_authorize
      post(api_iso_images_url, :params => {:action => 'edit'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'updates an iso image with an appropriate role' do
      api_basic_authorize collection_action_identifier(:iso_images, :edit)

      post(api_iso_images_url, :params => gen_request(:edit, 'id' => iso_image.id, 'name' => 'name updated'))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["results"].first).to include('href' => api_iso_image_url(nil, iso_image))
      expect(iso_image.reload.name).to eq('name updated')
    end
  end

  describe 'POST /api/iso_images/:id' do
    it 'forbids updating an iso image without an appropriate role' do
      api_basic_authorize
      post(api_iso_image_url(nil, iso_image), :params => {:action => 'edit', :name => 'name updated'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'updates an iso image with an appropriate role' do
      api_basic_authorize collection_action_identifier(:iso_images, :edit)

      post(api_iso_image_url(nil, iso_image), :params => {:action => 'edit', :name => 'name updated'})

      expect(iso_image.reload.name).to eq('name updated')
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('href' => api_iso_image_url(nil, iso_image))
    end
  end
end
