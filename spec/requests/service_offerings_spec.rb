describe "ServiceOfferings API" do
  it "forbids access without an appropriate role" do
    api_basic_authorize

    get(api_service_offerings_url)

    expect(response).to have_http_status(:forbidden)
  end

  it "allows access with an appropriate role" do
    api_basic_authorize action_identifier(:service_offerings, :read, :collection_actions, :get)

    instance = ServiceOffering.create!

    get(api_service_offerings_url)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["resources"]).to include("href" => api_service_offering_url(nil, instance))
  end

  it "forbids access to an instance without an appropriate role" do
    api_basic_authorize

    instance = ServiceOffering.create!

    get(api_service_offering_url(nil, instance))

    expect(response).to have_http_status(:forbidden)
  end

  it "allows access to an instance with an appropriate role" do
    api_basic_authorize action_identifier(:service_offerings, :read, :resource_actions, :get)

    instance = ServiceOffering.create!

    get(api_service_offering_url(nil, instance))

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(
      "href" => api_service_offering_url(nil, instance),
      "id"   => instance.id.to_s
    )
  end

  it "allows access to an instances service_parameters_sets with an appropriate role" do
    api_basic_authorize action_identifier(:service_offerings, :read, :resource_actions, :get)

    instance = ServiceOffering.create!
    sub_resource = instance.service_parameters_sets.create!

    get(api_service_offering_service_parameters_sets_url(nil, instance))

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["resources"]).to eq([{"href" => api_service_offering_service_parameters_set_url(nil, instance, sub_resource)}])
  end
end
