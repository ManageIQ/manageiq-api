module Api
  class BaseController
    module Authentication
      SYSTEM_TOKEN_TTL = 30.seconds

      #
      # REST APIs Authenticator and Redirector
      #
      def require_api_user_or_token
        if request.headers[HttpHeaders::MIQ_TOKEN]
          authenticate_with_system_token(request.headers[HttpHeaders::MIQ_TOKEN])
        elsif request.headers[HttpHeaders::AUTH_TOKEN]
          authenticate_with_user_token(request.headers[HttpHeaders::AUTH_TOKEN])
        else
          success = authenticate_with_http_basic do |u, p|
            begin
              timeout = ::Settings.api.authentication_timeout.to_i_with_method
              user = User.authenticate(u, p, request, :require_user => true, :timeout => timeout)
              auth_user_obj = userid_to_userobj(user.userid)
              authorize_user_group(auth_user_obj)
              validate_user_identity(auth_user_obj)
              User.current_user = auth_user_obj
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
        request_http_basic_authentication("Application", ErrorSerializer.new(:unauthorized, e).serialize.to_json)
        log_api_response
      end

      def user_settings
        {
          :locale                     => I18n.locale.to_s.sub('-', '_'),
          :asynchronous_notifications => ::Settings.server.asynchronous_notifications,
        }.merge(User.current_user.settings)
      end

      def userid_to_userobj(userid)
        User.lookup_by_identity(userid)
      end

      def authorize_user_group(user_obj)
        group_name = request.headers[HttpHeaders::MIQ_GROUP]
        if group_name.present?
          group_name = CGI.unescape(group_name)
          group_obj = user_obj.miq_groups.find_by(:description => group_name)
          raise AuthenticationError, "Invalid Authorization Group #{group_name} specified" if group_obj.nil?
          user_obj.current_group_by_description = group_name
        elsif user_obj.current_group.nil? && user_obj.miq_groups.present?
          user_obj.change_current_group
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

      def authenticate_with_user_token(auth_token)
        if !api_token_mgr.token_valid?(auth_token)
          raise AuthenticationError, "Invalid Authentication Token #{auth_token} specified"
        else
          userid = api_token_mgr.token_get_info(auth_token, :userid)
          raise AuthenticationError, "Invalid Authentication Token #{auth_token} specified" unless userid

          auth_user_obj = userid_to_userobj(userid)

          unless request.headers['X-Auth-Skip-Token-Renewal'] == 'true'
            api_token_mgr.reset_token(auth_token)
          end

          authorize_user_group(auth_user_obj)
          validate_user_identity(auth_user_obj)
          User.current_user = auth_user_obj
        end
      end

      def authenticate_with_system_token(x_miq_token)
        @miq_token_hash = YAML.load(MiqPassword.decrypt(x_miq_token))

        validate_system_token_server(@miq_token_hash[:server_guid])
        validate_system_token_timestamp(@miq_token_hash[:timestamp])

        User.authorize_user(@miq_token_hash[:userid])

        auth_user_obj = userid_to_userobj(@miq_token_hash[:userid])

        authorize_user_group(auth_user_obj)
        validate_user_identity(auth_user_obj)
        User.current_user = auth_user_obj
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
    end
  end
end
