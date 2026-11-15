module Api
  class UserTokenService
    TYPES = %w(api ui ws).freeze

    def initialize(config = ApiConfig, args = {})
      @config = config
      @svc_options = args
    end

    def token_mgr(type)
      @token_mgr ||= {}
      case type
      when 'api', 'ui' # The default API token and UI token share the same TokenStore
        @token_mgr['api'] ||= new_token_mgr(base_config[:module], base_config[:name], api_config)
      when 'ws'
        @token_mgr['ws'] ||= TokenManager.new('ws', :token_ttl => -> { ::Settings.session.timeout })
      end
    end

    # API Settings with additional token ttl's
    #
    def api_config
      @api_config ||= ::Settings[base_config[:module]].to_hash
    end

    def generate_token(user_or_id, requester_type, token_ttl: nil)
      if user_or_id.kind_of?(User)
        userid = user_or_id.userid.downcase
      else
        userid = user_or_id.downcase
        validate_userid(userid)
      end
      validate_requester_type(requester_type)

      # Additional Requester type token ttl's for authentication
      type_to_ttl_override = {'ui' => ::Settings.session.timeout}

      token_ttl ||= type_to_ttl_override[requester_type]

      $api_log.info("Generating Authentication Token for userid: #{userid} requester_type: #{requester_type} token_ttl: #{token_ttl}")

      token_metadata = { :userid => userid, :token_ttl_override => token_ttl }
      token_metadata[:requester_type] = requester_type if requester_type != "api"
      token_mgr(requester_type).gen_token(token_metadata)
    end

    def validate_requester_type(requester_type)
      return if TYPES.include?(requester_type)
      requester_types = TYPES.join(', ')
      raise "Invalid requester_type #{requester_type} specified, valid types are: #{requester_types}"
    end

    private

    def base_config
      @config[:base]
    end

    def log_kv(key, val, pref = "")
      $api_log.info("#{pref}  #{key.to_s.ljust([24, key.to_s.length].max, ' ')}: #{val}")
    end

    def new_token_mgr(mod, name, api_config)
      token_ttl = api_config[:token_ttl]

      options                = {}
      options[:token_ttl]    = -> { token_ttl.to_i_with_method } if token_ttl

      log_init(mod, name, options) if @svc_options[:log_init]
      TokenManager.new(mod, options)
    end

    def log_init(mod, name, options)
      $api_log.info("")
      $api_log.info("Creating new Token Manager for the #{name}")
      $api_log.info("   Server  session_store: #{::Settings.server.session_store}")
      $api_log.info("   Token Manager  module: #{mod}")
      $api_log.info("   Token Manager options:")
      options.each { |key, val| log_kv(key, val, "    ") }
      $api_log.info("")
    end

    def validate_userid(userid)
      raise "Invalid userid #{userid} specified" unless User.in_my_region.where('lower(userid) = ?', userid.downcase).exists?
    end
  end
end
