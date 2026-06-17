module Api
  class BaseController
    module Authentication
      class AuthenticationError < StandardError; end

      SYSTEM_TOKEN_TTL = 30.seconds

      def auth_mechanism
        if request.headers[HttpHeaders::MIQ_TOKEN]
          :system
        elsif request.headers[HttpHeaders::AUTH_TOKEN]
          :token
        elsif request.headers["HTTP_AUTHORIZATION"].try(:match, /^Bearer (.*)/)
          :jwt
        elsif request.headers["HTTP_AUTHORIZATION"]
          # For AJAX requests the basic auth type should be distinguished
          request.headers['X-REQUESTED-WITH'] == 'XMLHttpRequest' ? :basic_async : :basic
        elsif request.cookies['_vmdb_session'] || request.x_csrf_token
          # Even if the session cookie is not set, we want to consider a request
          # as a UI authentication request. (Previously that would force a login popup.)
          :ui_session
        else
          # no attempt at authentication, usually falls back to :basic
          nil
        end
      end

      def authenticate_user
        case auth_mechanism
        when :system
          authenticate_with_system_token(request.headers[HttpHeaders::MIQ_TOKEN])
        when :token
          authenticate_with_user_token(request.headers[HttpHeaders::AUTH_TOKEN])
        when :ui_session
          raise AuthenticationError unless valid_ui_session?
          auth_user(session[:userid])
        when :jwt
          authenticate_with_jwt
        when :basic, :basic_async, nil
          success = authenticate_with_http_basic { |u, p| basic_authentication(u, p) }
          raise AuthenticationError unless success
        end
        log_api_auth
      end

      #
      # REST APIs Authenticator and Redirector
      #
      def require_api_user_or_token
        authenticate_user
      rescue AuthenticationError => e
        api_log_error("AuthenticationError: #{e.message}")
        response.headers["Content-Type"] = "application/json"
        error_message = ErrorSerializer.new(:unauthorized, e).serialize(true).to_json
        render :status => 401, :json => error_message
        log_api_response
      end

      #
      # Attempt auth if desired, but flow through on failure
      #
      def optional_api_user_or_token
        authenticate_user
      rescue AuthenticationError => e
        api_log_warn("AuthenticationError: #{e.message} (on #{request.method} that doesn't require it... ignoring)")
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

      def clear_cached_current_user
        User.current_user = nil
      end

      def api_token_mgr
        Environment.user_token_service.token_mgr('api')
      end

      def auth_user(user_or_id)
        auth_user_obj = if user_or_id.kind_of?(User)
                          user_or_id
                        else
                          User.lookup_by_identity(user_or_id, lookup_scope: :api_includes)
                        end

        authorize_user_group(auth_user_obj)
        validate_user_identity(auth_user_obj)
        User.current_user = auth_user_obj
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
      rescue TokenManager::MissingTokenError
        raise AuthenticationError, "Missing Authentication Token (#{HttpHeaders::AUTH_TOKEN})"
      rescue TokenManager::EmptyTokenError
        raise AuthenticationError, "Empty Authentication Token (#{HttpHeaders::AUTH_TOKEN})"
      end

      def authenticate_with_system_token(x_miq_token)
        @miq_token_hash = YAML.load(ManageIQ::Password.decrypt(x_miq_token))

        validate_system_token_server(@miq_token_hash[:server_guid])
        validate_system_token_timestamp(@miq_token_hash[:timestamp])

        if @miq_token_hash[:user_metadata].present?
          User.authorize_user_with_system_token(@miq_token_hash[:userid], @miq_token_hash[:user_metadata])
        else
          User.authorize_user(@miq_token_hash[:userid])
        end

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
          valid_authenticity_token?(session, request.x_csrf_token) || request.method == 'GET', # CSRF token be set and valid (or GET)
          session[:userid].present?, # session has a userid stored
          request.origin.nil? || request.origin == request.base_url # origin header if set matches base_url
        ].all?
      end

      def authenticate_with_jwt
        timeout = ::Settings.api.authentication_timeout.to_i_with_method
        user_header = request.headers["X-REMOTE-USER"]&.force_encoding("UTF-8")
        user = User.authenticate(user_header, "", request, :require_user => true, :timeout => timeout)
        auth_user(user.userid)
      rescue => e
        raise AuthenticationError, "Failed to Authenticate with JWT - error #{e}"
      end

      def basic_authentication(username, password)
        timeout = ::Settings.api.authentication_timeout.to_i_with_method
        user = User.authenticate(username, password, request, :require_user => true, :timeout => timeout, :lookup_scope => :api_includes)
        auth_user(user)
      rescue MiqException::MiqEVMLoginError => e
        raise AuthenticationError, e.message
      end
    end
  end
end
