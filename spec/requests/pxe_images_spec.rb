RSpec.describe 'PxeImages API' do
  let!(:pxe_image)  { FactoryBot.create(:pxe_image, :pxe_image_type => image_type) }
  let!(:image_type) { FactoryBot.create(:pxe_image_type) }
  let!(:template_1) { FactoryBot.create(:customization_template, :pxe_image_type => image_type) }
  let!(:template_2) { FactoryBot.create(:customization_template, :pxe_image_type => image_type) }

  describe 'GET /api/pxe_images' do
    let(:url) { api_pxe_images_url }

    it 'lists all pxe images with an appropriate role' do
      api_basic_authorize collection_action_identifier(:pxe_images, :read, :get)
      get(url)
      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'pxe_images',
        'resources' => [
          hash_including('href' => api_pxe_image_url(nil, pxe_image))
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

  describe 'GET /api/pxe_images/:id' do
    let(:url) { api_pxe_image_url(nil, pxe_image) }

    it 'will show a pxe image with an appropriate role' do
      api_basic_authorize action_identifier(:pxe_images, :read, :resource_actions, :get)
      get(url)
      expect(response.parsed_body).to include('href' => api_pxe_image_url(nil, pxe_image))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/pxe_images/:id/customization_templates' do
    let(:url) { "/api/pxe_images/#{pxe_image.id}/customization_templates" }

    it 'lists all customization templates for a pxe image' do
      api_basic_authorize subcollection_action_identifier(:pxe_images, :customization_templates, :read, :get)
      get(url)
      expect_result_resources_to_include_hrefs(
        "resources",
        [
          api_pxe_image_customization_template_url(nil, pxe_image, template_1),
          api_pxe_image_customization_template_url(nil, pxe_image, template_2),
        ]
      )
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/pxe_images/:id/customization_templates/:id' do
    let(:url) { "/api/pxe_images/#{pxe_image.id}/customization_templates/#{template_1.id}" }

    it "will show a single customization template of a pxe image" do
      api_basic_authorize subcollection_action_identifier(:pxe_images, :customization_templates, :read, :get)
      get(url)
      expect_result_to_match_hash(
        response.parsed_body,
        "href"              => api_pxe_image_customization_template_url(nil, pxe_image, template_1),
        "id"                => template_1.id.to_s,
        "pxe_image_type_id" => image_type.id.to_s,
        "name"              => template_1.name
      )
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
