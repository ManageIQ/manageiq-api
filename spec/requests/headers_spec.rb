RSpec.describe "Headers" do
  describe "Accept" do
    it "returns JSON when set to application/json" do
      api_basic_authorize

      get api_entrypoint_url, :headers => {"Accept" => "application/json"}

      expect(response.parsed_body).to include("name" => "API", "description" => "REST API")
      expect(response).to have_http_status(:ok)
    end

    it "returns JSON when not provided" do
      api_basic_authorize

      get api_entrypoint_url

      expect(response.parsed_body).to include("name" => "API", "description" => "REST API")
      expect(response).to have_http_status(:ok)
    end

    it "responds with an error for unsupported mime-types" do
      api_basic_authorize

      get api_entrypoint_url, :headers => {"Accept" => "application/xml"}

      expected = {
        "error" => a_hash_including(
          "kind"    => "unsupported_media_type",
          "message" => "Invalid Response Format application/xml requested",
          "klass"   => "Api::UnsupportedMediaTypeError"
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:unsupported_media_type)
    end
  end

  describe "Content-Type" do
    it "accepts JSON by default" do
      api_basic_authorize(collection_action_identifier(:groups, :create))

      post api_groups_url, :params => {:description => "foo"}

      expect(response).to have_http_status(:ok)
    end

    it "will accept JSON when set to application/json" do
      api_basic_authorize(collection_action_identifier(:groups, :create))

      post(api_groups_url,
           :params  => {:description => "foo"},
           :headers => {"Content-Type" => "application/json"})

      expect(response).to have_http_status(:ok)
    end

    it "will ignore the Content-Type" do
      api_basic_authorize(collection_action_identifier(:groups, :create))

      post(api_groups_url,
           :params  => {:description => "foo"},
           :headers => {"Content-Type" => "application/xml"})

      expect(response).to have_http_status(:ok)
    end
  end

  describe "Response Headers" do
    it "returns some headers related to security" do
      api_basic_authorize

      get(api_entrypoint_url)

      expected = {
        "X-Content-Type-Options"            => "nosniff",
        "X-Download-Options"                => "noopen",
        "X-Frame-Options"                   => "SAMEORIGIN",
        "X-Permitted-Cross-Domain-Policies" => "none",
        "X-XSS-Protection"                  => "1; mode=block"
      }
      expect(response.headers.to_h).to include(expected)
      expect(content_security_policy_for("default-src")).to include("'self'")
      expect(content_security_policy_for("connect-src")).to include("'self'")
      expect(content_security_policy_for("frame-src") || content_security_policy_for("child-src")).to include("'self'")
      expect(content_security_policy_for("script-src")).to include("'unsafe-eval'", "'unsafe-inline'", "'self'")
      expect(content_security_policy_for("style-src")).to include("'unsafe-inline'", "'self'")
    end

    def content_security_policy_for(src)
      response.headers["Content-Security-Policy"].split(/\s*;\s*/).detect { |p| p.start_with?(src) }
    end
  end
end
