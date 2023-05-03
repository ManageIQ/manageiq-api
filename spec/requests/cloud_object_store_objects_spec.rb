describe "Cloud Object Store Objects API" do
  include Spec::Support::SupportsHelper

  context 'GET /api/cloud_object_store_objects' do
    it 'forbids access to cloud object store objects without an appropriate role' do
      api_basic_authorize

      get(api_cloud_object_store_objects_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns cloud object store objects with an appropriate role' do
      cloud_object_store_object = FactoryBot.create(:cloud_object_store_object)
      api_basic_authorize(collection_action_identifier(:cloud_object_store_objects, :read, :get))

      get(api_cloud_object_store_objects_url)

      expected = {
        'resources' => [{'href' => api_cloud_object_store_object_url(nil, cloud_object_store_object)}]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context 'GET /api/cloud_object_store_objects' do
    let(:cloud_object_store_object) { FactoryBot.create(:cloud_object_store_object) }

    it 'forbids access to a cloud object store object without an appropriate role' do
      api_basic_authorize

      get(api_cloud_object_store_object_url(nil, cloud_object_store_object))

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the cloud object store object with an appropriate role' do
      api_basic_authorize(action_identifier(:cloud_object_store_objects, :read, :resource_actions, :get))

      get(api_cloud_object_store_object_url(nil, cloud_object_store_object))

      expected = {
        'href' => api_cloud_object_store_object_url(nil, cloud_object_store_object)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
