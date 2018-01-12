require 'rails/engine'
module ManageIQ
  module Api
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::Api
      config.autoload_paths << root.join('app', 'controllers', 'api')
      config.autoload_paths << root.join('lib', 'services')
      config.autoload_paths << root.join('lib')

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

      def vmdb_plugin?
        true
      end
    end
  end
end
