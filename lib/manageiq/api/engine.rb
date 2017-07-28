require 'rails/engine'
module ManageIQ
  module Api
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::Api
      config.autoload_paths << File.expand_path(root.join('app', 'controllers', 'api'), __FILE__)
      config.autoload_paths << File.expand_path(root.join('lib', 'services'), __FILE__)
      config.autoload_paths << File.expand_path(root.join('lib'), __FILE__)

      def vmdb_plugin?
        true
      end
    end
  end
end
