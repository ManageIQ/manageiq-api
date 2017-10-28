RSpec.describe "Creating" do
  it "responds OK if there is a resource at the top level" do
    api_basic_authorize(action_identifier(:roles, :create, :collection_actions))

    post(api_roles_url, :params => {:name => "Alice's Role"})

    expect(response).to have_http_status(:ok)
  end

  it "responds OK if there is a resource in the \"resource\" node" do
    api_basic_authorize(action_identifier(:roles, :create, :collection_actions))

    post(api_roles_url, :params => {:resource => {:name => "Alice's Role"}})

    expect(response).to have_http_status(:ok)
  end

  it "respondes OK if there is at least one resource in the \"resources\" node" do
    api_basic_authorize(action_identifier(:roles, :create, :collection_actions))

    post(api_roles_url, :params => {:resources => [{:name => "Alice's Role"}, {}]})

    expect(response).to have_http_status(:ok)
  end

  it "responds with Bad Request if there are no resources at the top level" do
    skip("Currently results in an internal server error")
    api_basic_authorize(action_identifier(:roles, :create, :collection_actions))

    post(api_roles_url)

    expect(response.parsed_body).to include_error_with_message("No roles resources were specified for the create action")
    expect(response).to have_http_status(:bad_request)
  end

  it "responds with Bad Request if there is a null resource in the \"resource\" node" do
    skip("Currently results in an internal server error")
    api_basic_authorize(action_identifier(:roles, :create, :collection_actions))

    post(api_roles_url, :params => {:resource => nil})

    expect(response.parsed_body).to include_error_with_message("No roles resources were specified for the create action")
    expect(response).to have_http_status(:bad_request)
  end

  it "responds with Bad Request if there is an emtpy resource in the \"resource\" node" do
    api_basic_authorize(action_identifier(:roles, :create, :collection_actions))

    post(api_roles_url, :params => {:resource => {}})

    expect(response.parsed_body).to include_error_with_message("No roles resources were specified for the create action")
    expect(response).to have_http_status(:bad_request)
  end

  it "responds with Bad Request if there are no resources at the top level" do
    api_basic_authorize(action_identifier(:roles, :create, :collection_actions))

    post(api_roles_url, :params => {:resources => []})

    expect(response.parsed_body).to include_error_with_message("No roles resources were specified for the create action")
    expect(response).to have_http_status(:bad_request)
  end

  it "responds with Bad Request if an id is present in the URL" do
    api_basic_authorize(action_identifier(:roles, :create, :collection_actions))

    post(api_role_url(nil, 123), :params => {:name => "Alice's Group"})

    expect(response.parsed_body).to include_error_with_message("Unsupported Action create for the roles resource specified")
    expect(response).to have_http_status(:bad_request)
  end

  it "responds with Bad Request if we specify an id in the body" do
    api_basic_authorize(action_identifier(:roles, :create, :collection_actions))

    post(api_roles_url, :params => {:id => 123, :name => "Alice's Group"})

    expect(response.parsed_body).to include_error_with_message("Resource id or href should not be specified for creating a new roles")
    expect(response).to have_http_status(:bad_request)
  end

  it "responds with Bad Request if we specify an href in the body" do
    api_basic_authorize(action_identifier(:roles, :create, :collection_actions))

    post(api_roles_url, :params => {:href => api_vm_url(nil, 123), :name => "Alice's Group"})

    expect(response.parsed_body).to include_error_with_message("Resource id or href should not be specified for creating a new roles")
    expect(response).to have_http_status(:bad_request)
  end
end
