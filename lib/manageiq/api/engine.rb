module ManageIQ
  module Api
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::Api

      config.autoload_paths << root.join('lib')
      config.autoload_paths << root.join('lib', 'services')

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

      def self.vmdb_plugin?
        true
      end

      def self.plugin_name
        _('REST API')
      end

      def self.init_loggers
        $api_log ||= Vmdb::Loggers.create_logger("api.log")
      end

      def self.apply_logger_config(config)
        Vmdb::Loggers.apply_config_value(config, $api_log, :level_api)
      end
    end
  end
end
