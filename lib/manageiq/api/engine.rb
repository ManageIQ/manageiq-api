require 'rails/engine'
module ManageIQ
  module Api
    class Engine < ::Rails::Engine
      isolate_namespace Api

      # NOTE:  If you are going to make changes to autoload_paths, please make
      # sure they are all strings.  Rails will push these paths into the
      # $LOAD_PATH.
      #
      # More info can be found in the ruby-lang bug:
      #
      #   https://bugs.ruby-lang.org/issues/14372
      #
      config.autoload_paths << root.join('lib', 'services').to_s
      config.autoload_paths << root.join('lib').to_s

      config.after_initialize do
        $api_log.info("Initializing Environment for #{::Api::ApiConfig.base[:name]}")
        $api_log.info("")
        $api_log.info("Static Configuration")
        ::Api::ApiConfig.base.each { |key, val| log_kv(key, val) }

        $api_log.info("")
        $api_log.info("Dynamic Configuration")
        ::Api::Environment.user_token_service.api_config.each { |key, val| log_kv(key, val) }
      end

      def self.log_kv(key, val)
        $api_log.info("  #{key.to_s.ljust([24, key.to_s.length].max, ' ')}: #{val}")
      end

      def self.plugin_name
        _('REST API')
      end

      def self.vmdb_plugin?
        true
      end
    end
  end
end
