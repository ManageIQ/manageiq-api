require 'rails/engine'
module ManageIQ
  module Api
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::Api
      config.autoload_paths << root.join('app', 'controllers', 'api').expand_path
      config.autoload_paths << root.join('lib', 'services').expand_path
      config.autoload_paths << root.join('lib').expand_path

      def vmdb_plugin?
        true
      end
    end
  end
end
