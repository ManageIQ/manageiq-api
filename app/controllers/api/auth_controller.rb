module Api
  class AuthController < BaseController
    skip_before_action :validate_api_action

    def show
      requester_type = fetch_and_validate_requester_type
      token_service = Environment.user_token_service
      auth_token = token_service.generate_token(User.current_user, requester_type)
      token_info = token_service.token_mgr(requester_type).token_get_info(auth_token)
      res = {
        :auth_token => auth_token,
        :token_ttl  => token_info[:token_ttl],
        :expires_on => token_info[:expires_on]
      }
      res[:requester_type] = token_info[:requester_type] if token_info[:requester_type]
      render_resource :auth, res
    end

    def destroy
      api_token_mgr.invalidate_token(request.headers[HttpHeaders::AUTH_TOKEN])
      head :no_content
    end

    private

    def fetch_and_validate_requester_type
      requester_type = params['requester_type'] || 'api'
      Environment.user_token_service.validate_requester_type(requester_type)
      requester_type
    rescue => err
      raise BadRequestError, err.to_s
    end
  end
end
