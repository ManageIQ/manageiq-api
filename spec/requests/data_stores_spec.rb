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
    expect_single_action_result(:success => true, :task => true, :message => /Deleting Data Store.*#{ds.id}/)
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

    post(api_data_stores_url, :params => {:action => 'delete', :resources => [{'id' => ds1.id}, {'id' => ds2.id}]})
    expect_multiple_action_result(2, :task => true, :success => true, :message => /Deleting Data Store/)
  end
end
