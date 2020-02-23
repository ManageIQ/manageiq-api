module Api
  class BaseController
    module Authentication
      require "net/http"
      require "uri"

      SYSTEM_TOKEN_TTL = 30.seconds

      def auth_mechanism
        if request.headers[HttpHeaders::MIQ_TOKEN]
          :system
        elsif request.headers[HttpHeaders::AUTH_TOKEN]
          :token
        elsif request.headers["HTTP_AUTHORIZATION"]
          if jwt_token
            :jwt
          else
            # For AJAX requests the basic auth type should be distinguished
            request.headers['X-REQUESTED-WITH'] == 'XMLHttpRequest' ? :basic_async : :basic
          end
        elsif request.x_csrf_token
          # Even if the session cookie is not set, we want to consider a request
          # as a UI authentication request. Otherwise the response would force
          # the browser to throw an undesired HTTP basic authentication dialog.
          :ui_session
        else
          # no attempt at authentication, usually falls back to :basic
          nil
        end
      end

      #
      # REST APIs Authenticator and Redirector
      #
      def require_api_user_or_token
        case auth_mechanism
        when :system
          authenticate_with_system_token(request.headers[HttpHeaders::MIQ_TOKEN])
        when :token
          authenticate_with_user_token(request.headers[HttpHeaders::AUTH_TOKEN])
        when :ui_session
          raise AuthenticationError unless valid_ui_session?
          auth_user(session[:userid])
        when :jwt
          authenticate_with_jwt(jwt_token)
        when :basic, :basic_async, nil
          success = authenticate_with_http_basic do |u, p|
            begin
              timeout = ::Settings.api.authentication_timeout.to_i_with_method

              if !User.admin?(u) && oidc_configuration?
                # Basic auth, user/password but configured against OpenIDC.
                # Let's authenticate as such and get a JWT for that user.
                #
                user_jwt   = get_jwt_token(u, p)
                token_info = validate_jwt_token(user_jwt)
                user_data, membership = user_details_from_jwt(token_info)
                define_jwt_request_headers(user_data, membership)
              end
              user = User.authenticate(u, p, request, :require_user => true, :timeout => timeout)
              auth_user(user.userid)
            rescue MiqException::MiqEVMLoginError => e
              raise AuthenticationError, e.message
            end
          end
          raise AuthenticationError unless success
        end
        log_api_auth
      rescue AuthenticationError => e
        api_log_error("AuthenticationError: #{e.message}")
        response.headers["Content-Type"] = "application/json"
        case auth_mechanism
        when :jwt, :system, :token, :ui_session, :basic_async
          render :status => 401, :json => ErrorSerializer.new(:unauthorized, e).serialize(true).to_json
        when :basic, nil
          request_http_basic_authentication("Application", ErrorSerializer.new(:unauthorized, e).serialize(true).to_json)
        end
        log_api_response
      end

      def user_settings
        {
          :locale                     => I18n.locale.to_s.sub('-', '_'),
          :asynchronous_notifications => ::Settings.server.asynchronous_notifications,
        }.merge(User.current_user.settings)
      end

      def authorize_user_group(user_obj)
        group_name = request.headers[HttpHeaders::MIQ_GROUP]
        if group_name.present?
          group_name = CGI.unescape(group_name)
          group_obj = user_obj.miq_groups.find_by(:description => group_name)
          raise AuthenticationError, "Invalid Authorization Group #{group_name} specified" if group_obj.nil?
          user_obj.current_group_by_description = group_name
        end
      end

      def validate_user_identity(user_obj)
        missing_feature = User.missing_user_features(user_obj)
        if missing_feature
          raise AuthenticationError, "Invalid User #{user_obj.userid} specified, User's #{missing_feature} is missing"
        end
      end

      private

      def api_token_mgr
        Environment.user_token_service.token_mgr('api')
      end

      def auth_user(userid)
        auth_user_obj = User.lookup_by_identity(userid)
        authorize_user_group(auth_user_obj)
        validate_user_identity(auth_user_obj)
        User.current_user = auth_user_obj
      end

      def authenticate_with_jwt(jwt_token)
        token_info = validate_jwt_token(jwt_token)
        user_data, membership = user_details_from_jwt(token_info)
        define_jwt_request_headers(user_data, membership)

        timeout = ::Settings.api.authentication_timeout.to_i_with_method
        user = User.authenticate(user_data[:username], "", request, :require_user => true, :timeout => timeout)
        auth_user(user.userid)
      rescue => e
        raise AuthenticationError, "Failed to Authenticate with JWT - error #{e}"
      end

      def authenticate_with_user_token(auth_token)
        if !api_token_mgr.token_valid?(auth_token)
          raise AuthenticationError, "Invalid Authentication Token #{auth_token} specified"
        else
          userid = api_token_mgr.token_get_info(auth_token, :userid)
          raise AuthenticationError, "Invalid Authentication Token #{auth_token} specified" unless userid

          unless request.headers['X-Auth-Skip-Token-Renewal'] == 'true'
            api_token_mgr.reset_token(auth_token)
          end

          auth_user(userid)
        end
      end

      def authenticate_with_system_token(x_miq_token)
        @miq_token_hash = YAML.load(ManageIQ::Password.decrypt(x_miq_token))

        validate_system_token_server(@miq_token_hash[:server_guid])
        validate_system_token_timestamp(@miq_token_hash[:timestamp])

        User.authorize_user(@miq_token_hash[:userid])

        auth_user(@miq_token_hash[:userid])
      rescue => err
        api_log_error("Authentication Failed with System Token\nX-MIQ-Token: #{x_miq_token}\nError: #{err}")
        raise AuthenticationError, "Invalid System Authentication Token specified"
      end

      def validate_system_token_server(server_guid)
        raise "Missing server_guid" if server_guid.blank?
        raise "Invalid server_guid #{server_guid} specified" unless MiqServer.where(:guid => server_guid).exists?
      end

      def validate_system_token_timestamp(timestamp)
        raise "Missing timestamp" if timestamp.blank?
        raise "Invalid timestamp #{timestamp} specified" if SYSTEM_TOKEN_TTL.ago.utc > timestamp
      end

      def valid_ui_session?
        [
          valid_authenticity_token?(session, request.x_csrf_token), # CSRF token be set and valid
          session[:userid].present?,                                # session has a userid stored
          request.origin.nil? || request.origin == request.base_url # origin header if set matches base_url
        ].all?
      end

      # Support for OAuth2 Authentication
      #
      # Some of this stuff should probably live in manageiq/app/models/authenticator/httpd.rb
      #
      HTTPD_OPENIDC_CONF = Pathname.new("/etc/httpd/conf.d/manageiq-external-auth-openidc.conf")

      def jwt_token
        @jwt_token ||= begin
          jwt_token_match = request.headers["HTTP_AUTHORIZATION"].match(/^Bearer (.*)/)
          jwt_token_match[1] if jwt_token_match
        end
      end

      def oidc_configuration?
        auth_config = Settings.authentication
        auth_config.mode == "httpd"           &&
          auth_config.oidc_enabled            &&
          auth_config.provider_type == "oidc" &&
          HTTPD_OPENIDC_CONF.exist?
      end

      def httpd_oidc_config
        @httpd_oidc_config ||= HTTPD_OPENIDC_CONF.readlines.collect(&:chomp)
      end

      def httpd_oidc_config_param(name)
        param_spec = httpd_oidc_config.find { |line| line =~ /^#{name} .*/i }
        return "" if param_spec.blank?

        param_match = param_spec.match(/^#{name} (.*)/i)
        param_match ? param_match[1].strip : ""
      end

      def oidc_provider_metadata
        @oidc_provider_metadata ||= begin
          oidc_provider_metadata_url = httpd_oidc_config_param("OIDCProviderMetadataURL")
          if oidc_provider_metadata_url.blank?
            {}
          else
            uri = URI.parse(oidc_provider_metadata_url)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = (uri.scheme == "https")
            response = http.request(Net::HTTP::Get.new(uri.request_uri))
            JSON.parse(response.body)
          end
        end
      end

      def oidc_metadata_url_endpoint(oidc_param, metadata_url_key)
        endpoint = httpd_oidc_config_param(oidc_param)
        endpoint = oidc_provider_metadata[metadata_url_key] if endpoint.blank?
        raise AuthenticationError, "Invalid #{HTTPD_OPENIDC_CONF} configuration, missing #{oidc_param} or OIDCProviderMetadataURL #{metadata_url_key} entry" if endpoint.blank?

        endpoint
      end

      def oidc_token_endpoint
        @oidc_token_endpoint ||= oidc_metadata_url_endpoint("OIDCProviderTokenEndpoint", "token_endpoint")
      end

      def oidc_token_introspection_endpoint
        @oidc_token_introspection_endpoint ||= oidc_metadata_url_endpoint("OIDCOAuthIntrospectionEndpoint", "token_introspection_endpoint")
      end

      def oidc_client_id
        @oidc_client_id ||= httpd_oidc_config_param("OIDCClientId")
      end

      def oidc_client_secret
        @oidc_client_secret ||= httpd_oidc_config_param("OIDCClientSecret")
      end

      def oidc_scope
        @oidc_scope ||= httpd_oidc_config_param("OIDCScope")
      end

      def get_jwt_token(username, password)
        uri = URI.parse(oidc_token_endpoint)
        request_params = {
          "grant_type" => "password",
          "username"   => username,
          "password"   => password
        }
        request_params["scope"] = oidc_scope if oidc_scope.present?

        request = Net::HTTP::Post.new(uri)
        request.basic_auth(oidc_client_id, oidc_client_secret)
        request.form_data = request_params

        http_params     = {:use_ssl => (uri.scheme == "https")}
        response        = Net::HTTP.start(uri.hostname, uri.port, http_params) { |http| http.request(request) }
        parsed_response = JSON.parse(response.body)
        raise parsed_response["error_description"] if parsed_response["error"].present?

        parsed_response["access_token"]
      rescue => e
        raise AuthenticationError, "Failed to get a JWT Token for user #{username} - error #{e}"
      end

      def validate_jwt_token(jwt_token)
        uri = URI.parse(oidc_token_introspection_endpoint)
        request_params = {
          "token" => jwt_token
        }
        request_params["scope"] = oidc_scope if oidc_scope.present?

        request = Net::HTTP::Post.new(uri)
        request.basic_auth(oidc_client_id, oidc_client_secret)
        request.form_data = request_params

        http_params     = {:use_ssl => (uri.scheme == "https")}
        response        = Net::HTTP.start(uri.hostname, uri.port, http_params) { |http| http.request(request) }
        parsed_response = JSON.parse(response.body)
        raise "Invalid access token, JWT is inactive" if parsed_response["active"] != true

        # Return the Token Introspection result
        parsed_response
      rescue => e
        raise AuthenticationError, "Failed to Validate the JWT - error #{e}"
      end

      def user_details_from_jwt(token_info)
        user_attrs = {
          :username  => token_info["preferred_username"],
          :fullname  => token_info["name"],
          :firstname => token_info["given_name"],
          :lastname  => token_info["family_name"],
          :email     => token_info["email"],
          :domain    => token_info["domain"]
        }
        [user_attrs, Array(token_info["groups"])]
      end

      def define_jwt_request_headers(user_data, membership)
        request.headers["X-REMOTE-USER"]           = user_data[:username]
        request.headers["X-REMOTE-USER-FULLNAME"]  = user_data[:fullname]
        request.headers["X-REMOTE-USER-FIRSTNAME"] = user_data[:firstname]
        request.headers["X-REMOTE-USER-LASTNAME"]  = user_data[:lastname]
        request.headers["X-REMOTE-USER-EMAIL"]     = user_data[:email]
        request.headers["X-REMOTE-USER-DOMAIN"]    = user_data[:domain]
        request.headers["X-REMOTE-USER-GROUPS"]    = membership.join(',')
      end
    end
  end
end
