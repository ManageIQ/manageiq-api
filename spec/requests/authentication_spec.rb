#
# REST API Request Tests - /api authentication
#
describe "Authentication API" do
  ENTRYPOINT_KEYS = %w(name description version versions identity collections)

  context "Basic Authentication" do
    example "the user is challenged to use Basic Authentication when no credentials are provided" do
      get api_entrypoint_url

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to match("Basic")
    end

    it "test basic authentication with bad credentials" do
      api_basic_authorize :user => 'baduser', :password => 'badpassword'

      get api_entrypoint_url

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to match("Basic")
    end

    it "test basic authentication with correct credentials" do
      api_basic_authorize

      get api_entrypoint_url

      expect(response).to have_http_status(:ok)
      expect_result_to_have_keys(ENTRYPOINT_KEYS)
    end

    it "test basic authentication with a user without a role" do
      @group.miq_user_role = nil
      @group.save

      api_basic_authorize

      get api_entrypoint_url

      expect(response.parsed_body).to include_error_with_message("User's Role is missing")
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to match("Basic")
    end

    it "test basic authentication with a user without a group" do
      @user.current_group = nil
      @user.save

      api_basic_authorize

      get api_entrypoint_url

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to match("Basic")
    end

    it "returns a correctly formatted versions href" do
      version_ident = "v#{ManageIQ::Api::VERSION}"
      api_basic_authorize

      get api_entrypoint_url(version_ident)

      expected = {
        "versions" => [a_hash_including("href" => api_entrypoint_url(version_ident))]
      }
      expect(response.parsed_body).to include(expected)
    end

    it "returns a correctly formatted collection hrefs" do
      api_basic_authorize

      get api_entrypoint_url

      collection_names = Api::ApiConfig.collections.to_h.select { |_, v| v.options.include?(:collection) }.keys
      hrefs = collection_names.collect { |name| url_for(:controller => name, :action => "index") }
      expected = {
        "collections" => a_collection_containing_exactly(
          *hrefs.collect { |href| a_hash_including("href" => href) }
        )
      }
      expect(response.parsed_body).to include(expected)
    end
  end

  context "Basic Authentication with Group Authorization" do
    let(:group1) { FactoryBot.create(:miq_group, :miq_user_role => @role) }
    let(:group2) { FactoryBot.create(:miq_group, :miq_user_role => @role) }

    before(:each) do
      @user.miq_groups = [group1, group2, @user.current_group]
      @user.current_group = group1
    end

    it "test basic authentication with incorrect group" do
      api_basic_authorize

      get api_entrypoint_url, :headers => {Api::HttpHeaders::MIQ_GROUP => "bogus_group"}

      expect(response.parsed_body).to include_error_with_message("Invalid Authorization Group bogus_group specified")
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to match("Basic")
    end

    it "test basic authentication with a primary group" do
      api_basic_authorize

      get api_entrypoint_url, :headers => {Api::HttpHeaders::MIQ_GROUP => group1.description}

      expect(response).to have_http_status(:ok)
    end

    it "test basic authentication with a secondary group" do
      api_basic_authorize

      get api_entrypoint_url, :headers => {Api::HttpHeaders::MIQ_GROUP => group2.description}

      expect(response).to have_http_status(:ok)
    end
  end

  context "Group Authorization with special characters" do
    let(:special_char_group) { FactoryBot.create(:miq_group, :description => "équipe", :miq_user_role => @role) }

    it "permits group headers to be specified with properly escaped descriptions" do
      @user.miq_groups << special_char_group
      api_basic_authorize

      get api_entrypoint_url, :headers => {Api::HttpHeaders::MIQ_GROUP => CGI.escape(special_char_group.description)}

      expect(response).to have_http_status(:ok)
    end
  end

  context "Authentication/Authorization Identity" do
    let(:group1) { FactoryBot.create(:miq_group, :miq_user_role => @role) }
    let(:group2) { FactoryBot.create(:miq_group, :miq_user_role => @role) }

    before do
      @user.miq_groups = [group1, group2, @user.current_group]
      @user.current_group = group1
    end

    it "basic authentication with a secondary group" do
      api_basic_authorize

      get api_entrypoint_url, :headers => {Api::HttpHeaders::MIQ_GROUP => group2.description}

      expect(response).to have_http_status(:ok)
      expect_result_to_have_keys(ENTRYPOINT_KEYS)
      expect_result_to_match_hash(
        response.parsed_body["identity"],
        "userid"     => @user.userid,
        "name"       => @user.name,
        "user_href"  => "/api/users/#{@user.id}",
        "group"      => group2.description,
        "group_href" => "/api/groups/#{group2.id}",
        "role"       => @role.name,
        "role_href"  => "/api/roles/#{group2.miq_user_role.id}",
        "tenant"     => @group.tenant.name,
        "groups"     => a_collection_containing_exactly(*@user.miq_groups.pluck(:description)),
        "miq_groups" => a_collection_including(
          hash_including("href" => api_group_url(nil, @user.miq_groups.first))
        )
      )
      expect(response.parsed_body["identity"]["groups"]).to match_array(@user.miq_groups.pluck(:description))
    end

    it "querying user's authorization" do
      api_basic_authorize

      get api_entrypoint_url, :params => { :attributes => "authorization" }

      expect(response).to have_http_status(:ok)

      expected = {"authorization" => hash_including("product_features"),
                  "identity"      => a_hash_including("miq_groups" => a_collection_including(
                    hash_including("sui_product_features" => a_kind_of(Hash))
                  ))}
      ENTRYPOINT_KEYS.each { |k| expected[k] = anything }
      expect(response.parsed_body).to include(expected)
    end
  end

  context "Token Based Authentication with expired tokens" do
    before do
      RSpec::Mocks.with_temporary_scope do
        @token_manager = instance_double(TokenManager)
        allow(TokenManager).to receive(:new).and_return(@token_manager)
      end
    end

    it "fails authentication even with an initially valid token" do
      token = "expired_token"

      allow(@token_manager).to receive(:token_valid?).with(token).and_return(true)
      allow(@token_manager).to receive(:token_get_info).with(token, :userid).and_return(nil)

      get api_entrypoint_url, :headers => {Api::HttpHeaders::AUTH_TOKEN => token}

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "UI authentication against the rails session" do
    it 'succeeds with valid session and valid CSRF token' do
      # Inspired by https://relishapp.com/rspec/rspec-mocks/docs/configuring-responses/block-implementation
      # Store the original new method because we're going to mock it
      original_new = ActionDispatch::Request::Session.method(:new)
      # This is a little crazy: the session is not accessible before the HTTP request is fired,
      # therefore, we have to mock the new method, call the original and catch its response.
      # Then we can mock the :[] method on the response and so set session variables.
      # In the end the block can simply return the response as if nothing happened.
      expect(ActionDispatch::Request::Session).to receive(:new) do |*args|
        _session = original_new.call(*args) # Call the original method
        allow(_session).to receive(:[]).with(:userid).and_return(@user.userid) # session[:userid] = @user.userid
        _session # Return the result of the original method
      end

      expect_any_instance_of(Api::ApiController).to receive(:valid_authenticity_token?).and_return(true)
      get api_entrypoint_url, :headers => {'X-CSRF-TOKEN' => 'foo'}

      expect(response).to have_http_status(:ok)
    end

    it "fails with missing CSRF token" do
      get api_entrypoint_url
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['WWW-Authenticate']).not_to be_nil
    end

    it "fails with invalid CSRF token" do
      expect_any_instance_of(Api::ApiController).to receive(:valid_authenticity_token?).and_return(false)
      get api_entrypoint_url, :headers => {'X-CSRF-TOKEN' => 'foo'}
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['WWW-Authenticate']).to be_nil
    end

    it "fails with missing session and valid CSRF token" do
      expect_any_instance_of(Api::ApiController).to receive(:valid_authenticity_token?).and_return(true)
      get api_entrypoint_url, :headers => {'X-CSRF-TOKEN' => 'foo'}
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['WWW-Authenticate']).to be_nil
    end
  end

  context "Token Based Authentication" do
    %w(sql memory).each do |session_store|
      context "when using a #{session_store} session store" do
        before { stub_settings_merge(:server => {:session_store => session_store}) }

        it "gets a token based identifier" do
          api_basic_authorize

          get api_auth_url

          expect(response).to have_http_status(:ok)
          expect_result_to_have_keys(%w(auth_token token_ttl expires_on))
        end

        it "authentication using a bad token" do
          get api_entrypoint_url, :headers => {Api::HttpHeaders::AUTH_TOKEN => "badtoken"}

          expect(response).to have_http_status(:unauthorized)
        end

        it "authentication using a bad token doesn't fallback to HTTP Basic" do
          get api_entrypoint_url, :headers => {Api::HttpHeaders::AUTH_TOKEN => "badtoken"}

          expect(response.headers.keys).not_to include('WWW-Authenticate')
        end

        it "authentication using a valid token" do
          api_basic_authorize

          get api_auth_url

          expect(response).to have_http_status(:ok)
          expect_result_to_have_keys(%w(auth_token))

          auth_token = response.parsed_body["auth_token"]

          get api_entrypoint_url, :headers => {Api::HttpHeaders::AUTH_TOKEN => auth_token}

          expect(response).to have_http_status(:ok)
          expect_result_to_have_keys(ENTRYPOINT_KEYS)
        end

        it "authentication using a valid token updates the token's expiration time" do
          api_basic_authorize

          get api_auth_url

          expect(response).to have_http_status(:ok)
          expect_result_to_have_keys(%w(auth_token token_ttl expires_on))

          auth_token = response.parsed_body["auth_token"]
          token_expires_on = response.parsed_body["expires_on"]

          tm = TokenManager.new("api")
          token_info = tm.token_get_info(auth_token)
          expect(token_info[:expires_on].utc.iso8601).to eq(token_expires_on)

          expect_any_instance_of(TokenManager).to receive(:reset_token).with(auth_token)
          get api_entrypoint_url, :headers => {Api::HttpHeaders::AUTH_TOKEN => auth_token}

          expect(response).to have_http_status(:ok)
          expect_result_to_have_keys(ENTRYPOINT_KEYS)
        end

        it "gets a token based identifier with the default API based token_ttl" do
          api_basic_authorize
          get api_auth_url

          expect(response).to have_http_status(:ok)
          expect_result_to_have_keys(%w(auth_token token_ttl expires_on))
          expect(response.parsed_body["token_ttl"]).to eq(::Settings.api.token_ttl.to_i_with_method)
        end

        it "gets a token based identifier with an invalid requester_type" do
          api_basic_authorize

          get api_auth_url, :params => { :requester_type => "bogus_type" }

          expect_bad_request(/invalid requester_type/i)
        end

        it "gets a token based identifier with a UI based token_ttl" do
          api_basic_authorize

          get api_auth_url, :params => { :requester_type => "ui" }

          expect(response).to have_http_status(:ok)
          expect_result_to_have_keys(%w(auth_token token_ttl expires_on))
          expect(response.parsed_body["token_ttl"]).to eq(::Settings.session.timeout.to_i_with_method)
        end

        it "gets a token based identifier with an updated UI based token_ttl" do
          ::Settings.session.timeout = 1234
          api_basic_authorize

          get api_auth_url, :params => { :requester_type => "ui" }

          expect(response).to have_http_status(:ok)
          expect_result_to_have_keys(%w(auth_token token_ttl expires_on))
          expect(response.parsed_body["token_ttl"]).to eq(1234)
        end

        it "forgets the current token when asked to" do
          api_basic_authorize

          get api_auth_url

          auth_token = response.parsed_body["auth_token"]

          expect_any_instance_of(TokenManager).to receive(:invalidate_token).with(auth_token)
          delete api_auth_url, :headers => {Api::HttpHeaders::AUTH_TOKEN => auth_token}
        end

        context 'Tokens for Web Sockets' do
          it 'gets a UI based token_ttl when requesting token for web sockets' do
            api_basic_authorize

            get api_auth_url, :params => { :requester_type => 'ws' }
            expect(response).to have_http_status(:ok)
            expect_result_to_have_keys(%w(auth_token token_ttl expires_on))
            expect(response.parsed_body["token_ttl"]).to eq(::Settings.session.timeout.to_i_with_method)
          end

          it 'cannot authorize user to api based on token that is dedicated for web sockets' do
            api_basic_authorize
            get api_auth_url, :params => { :requester_type => 'ws' }
            ws_token = response.parsed_body["auth_token"]

            get api_entrypoint_url, :headers => {Api::HttpHeaders::AUTH_TOKEN => ws_token}

            expect(response).to have_http_status(:unauthorized)
          end
        end
      end
    end
  end

  context "System Token Based Authentication" do
    AUTHENTICATION_ERROR = "Invalid System Authentication Token specified".freeze

    def systoken(server_guid, userid, timestamp)
      ManageIQ::Password.encrypt({:server_guid => server_guid, :userid => userid, :timestamp => timestamp}.to_yaml)
    end

    it "authentication using a bad token" do
      get api_entrypoint_url, :headers => {Api::HttpHeaders::MIQ_TOKEN => "badtoken"}

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to include(
        "error" => a_hash_including("kind" => "unauthorized", "message" => AUTHENTICATION_ERROR)
      )
    end

    it "authentication using a token with a bad server guid" do
      get(
        api_entrypoint_url,
        :headers => {Api::HttpHeaders::MIQ_TOKEN => systoken("bad_server_guid", @user.userid, Time.now.utc)}
      )

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to include(
        "error" => a_hash_including("kind" => "unauthorized", "message" => AUTHENTICATION_ERROR)
      )
    end

    it "authentication using a token with bad user" do
      get(
        api_entrypoint_url,
        :headers => {Api::HttpHeaders::MIQ_TOKEN => systoken(MiqServer.first.guid, "bad_user_id", Time.now.utc)}
      )

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to include(
        "error" => a_hash_including("kind" => "unauthorized", "message" => AUTHENTICATION_ERROR)
      )
    end

    it "authentication using a token with an old timestamp" do
      miq_token = systoken(MiqServer.first.guid, @user.userid, 10.minutes.ago.utc)

      get api_entrypoint_url, :headers => {Api::HttpHeaders::MIQ_TOKEN => miq_token}

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to include(
        "error" => a_hash_including("kind" => "unauthorized", "message" => AUTHENTICATION_ERROR)
      )
    end

    it "authentication using a valid token succeeds" do
      miq_token = systoken(MiqServer.first.guid, @user.userid, Time.now.utc)

      get api_entrypoint_url, :headers => {Api::HttpHeaders::MIQ_TOKEN => miq_token}

      expect(response).to have_http_status(:ok)
      expect_result_to_have_keys(ENTRYPOINT_KEYS)
    end
  end

  context "Role Based Authorization" do
    before do
      FactoryBot.create(:vm_vmware, :name => "vm1")
    end

    context "actions with single role identifier" do
      it "are rejected when user is not authorized with the single role identifier" do
        stub_api_action_role(:vms, :collection_actions, :get, :read, "vm_view_role1")
        api_basic_authorize

        get api_vms_url

        expect(response).to have_http_status(:forbidden)
      end

      it "are accepted when user is authorized with the single role identifier" do
        stub_api_action_role(:vms, :collection_actions, :get, :read, "vm_view_role1")
        api_basic_authorize "vm_view_role1"

        get api_vms_url

        expect_query_result(:vms, 1, 1)
      end
    end

    context "actions with multiple role identifiers" do
      it "are rejected when user is not authorized with any of the role identifiers" do
        stub_api_action_role(:vms, :collection_actions, :get, :read, %w(vm_view_role1 vm_view_role2))
        api_basic_authorize

        get api_vms_url

        expect(response).to have_http_status(:forbidden)
      end

      it "are accepted when user is authorized with at least one of the role identifiers" do
        stub_api_action_role(:vms, :collection_actions, :get, :read, %w(vm_view_role1 vm_view_role2))
        api_basic_authorize "vm_view_role2"

        get api_vms_url

        expect_query_result(:vms, 1, 1)
      end
    end
  end
end
