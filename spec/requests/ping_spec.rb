describe "PingController" do
  it "get" do
    get(api_ping_url)

    expect(response).to have_http_status(:success)
    expect(response.parsed_body).to eq("pong")
  end
end
