#
# REST API Request Tests - Datastores
#
# Datastore primary collections:
#   /api/data_stores
#
# Tests for:
# POST /api/data_stores/:id     - action "delete"
# POST /api/data_stores         - bulk action "delete"
# DELETE /api/data_stores/:id
#

describe "Data Stores API" do
  it "rejects delete request without appropriate role" do
    ds = FactoryBot.create(:storage_nfs)

    api_basic_authorize

    post(api_data_store_url(nil, ds), :params => { :action => 'delete' })

    expect(response).to have_http_status(:forbidden)
  end

  it "can delete a data store" do
    ds = FactoryBot.create(:storage_nfs)

    api_basic_authorize action_identifier(:data_stores, :delete, :resource_actions, :post)

    post(api_data_store_url(nil, ds), :params => { :action => "delete" })

    expected = {
      'message' => a_string_including("Deleting Data Store id:#{ds.id}"),
      'success' => true,
      'task_id' => a_kind_of(String)
    }

    expect(response.parsed_body).to include(expected)
    expect(response).to have_http_status(:ok)
  end

  it "can delete a data store with DELETE as a resource action" do
    ds = FactoryBot.create(:storage_nfs)

    api_basic_authorize action_identifier(:data_stores, :delete, :resource_actions, :delete)

    delete api_data_store_url(nil, ds)

    expect(response).to have_http_status(:no_content)
  end

  it "rejects delete request with DELETE as a resource action without appropriate role" do
    ds = FactoryBot.create(:storage_nfs)

    api_basic_authorize

    delete api_data_store_url(nil, ds)

    expect(response).to have_http_status(:forbidden)
  end

  it 'DELETE will raise an error if the cloud volume does not exist' do
    api_basic_authorize action_identifier(:data_stores, :delete, :resource_actions, :delete)

    delete(api_data_store_url(nil, 999_999))

    expect(response).to have_http_status(:not_found)
  end

  it 'can delete data stores through POST' do
    ds1 = FactoryBot.create(:storage_vmware)
    ds2 = FactoryBot.create(:storage_nfs)

    api_basic_authorize collection_action_identifier(:data_stores, :delete, :post)

    expected = {
      'results' => a_collection_including(
        a_hash_including(
          'success' => true,
          'message' => a_string_including("Deleting Data Store id:#{ds1.id}"),
          'task_id' => a_kind_of(String)
        ),
        a_hash_including(
          'success' => true,
          'message' => a_string_including("Deleting Data Store id:#{ds2.id}"),
          'task_id' => a_kind_of(String)
        )
      )
    }
    post(api_data_stores_url, :params => { :action => 'delete', :resources => [{ 'id' => ds1.id }, { 'id' => ds2.id }] })

    expect(response.parsed_body).to include(expected)
    expect(response).to have_http_status(:ok)
  end
end
