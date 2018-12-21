shared_examples "resource power operations" do |factory, operation|
  let!(:resource)             { FactoryBot.create(factory, :id => ApplicationRecord.id_in_region(1, region_remote.region)) }
  let(:api_client_collection) { double("/api/#{resource_type.pluralize}") }
  let(:api_client_connection) { double("ApiClient", :instances => api_client_collection) }
  let(:api_resource)          { double(resource_type) }
  let(:operation)             { operation }
  let(:region_remote)         { FactoryBot.create(:miq_region) }
  let(:url)                   { send("api_#{resource_type}_url", nil, resource) }

  it operation.to_s do
    api_basic_authorize(action_identifier(resource_type.pluralize.to_sym, operation))

    expect(api_client_connection).to receive(resource_type.pluralize).and_return(api_client_collection)
    expect(InterRegionApiMethodRelay).to receive(:api_client_connection_for_region).with(region_remote.region).and_return(api_client_connection)
    expect(api_client_collection).to receive(:find).with(resource.id).and_return(api_resource)
    expect(api_resource).to receive(operation)

    post(url, :params => gen_request(operation))
  end
end
