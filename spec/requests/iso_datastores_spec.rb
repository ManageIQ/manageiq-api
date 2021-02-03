RSpec.describe 'IsoDatastores API' do
  let(:ems) { FactoryBot.create(:ems_redhat) }
  let!(:iso_datastore) { FactoryBot.create(:iso_datastore, :ext_management_system => ems) }

  describe 'GET /api/iso_datastores' do
    let(:url) { api_iso_datastores_url }

    it 'lists all iso datastores with an appropriate role' do
      api_basic_authorize collection_action_identifier(:iso_datastores, :read, :get)
      get(url)
      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'iso_datastores',
        'resources' => [
          hash_including('href' => api_iso_datastore_url(nil, iso_datastore))
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

  describe 'GET /api/iso_datastores/:id' do
    let(:url) { api_iso_datastore_url(nil, iso_datastore) }

    it 'will show an iso datastore with an appropriate role' do
      api_basic_authorize action_identifier(:iso_datastores, :read, :resource_actions, :get)
      get(url)
      expect(response.parsed_body).to include('href' => api_iso_datastore_url(nil, iso_datastore))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/iso_datastores' do
    it 'forbids creating an iso datastore without an appropriate role' do
      api_basic_authorize
      post(api_iso_datastores_url, :params => {:action => 'create'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids deleting an iso datastore without an appropriate role' do
      api_basic_authorize
      post(api_iso_datastores_url, :params => {:action => 'delete'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'creates an iso datastore with an appropriate role' do
      params = {"ems_id" => ems.id.to_s}
      api_basic_authorize collection_action_identifier(:iso_datastores, :create)

      post(api_iso_datastores_url, :params => params)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["results"].first).to include(params)
    end

    it 'deletes an iso datastore with an appropriate role' do
      api_basic_authorize collection_action_identifier(:iso_datastores, :delete)

      post(api_iso_datastores_url, :params => gen_request(:delete, 'id' => iso_datastore.id, 'href' => api_iso_datastore_url(nil, iso_datastore)))

      expect(response).to have_http_status(:ok)
      expect(IsoDatastore.exists?(iso_datastore.id)).to be false
    end
  end

  describe 'POST /api/iso_datastores/:id' do
    it 'forbids deleting an iso datastore without an appropriate role' do
      api_basic_authorize
      post(api_iso_datastore_url(nil, iso_datastore), :params => {:action => 'delete'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'deletes an iso datastore with an appropriate role' do
      api_basic_authorize collection_action_identifier(:iso_datastores, :delete)

      expect do
        post(api_iso_datastore_url(nil, iso_datastore), :params => {:action => 'delete'})
      end.to change(IsoDatastore, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE /api/iso_datastores/:id' do
    it "deletes an iso datastore with an appropriate role" do
      api_basic_authorize(action_identifier(:iso_datastores, :delete))

      expect do
        delete(api_iso_datastore_url(nil, iso_datastore))
      end.to change(IsoDatastore, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'forbids deleting an iso datastore without an appropriate role' do
      api_basic_authorize
      delete(api_iso_datastore_url(nil, iso_datastore))
      expect(response).to have_http_status(:forbidden)
    end
  end
end
