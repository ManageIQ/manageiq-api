require "config"

module Api
  ApiConfig = ::Config::Options.new.tap do |o|
    plugins = Vmdb::Plugins.all.dup
    plugins.unshift(plugins.delete(ManageIQ::Api::Engine))
    plugins.each { |p| o.add_source!(p.root.join("config/api.yml").to_s) }

    o.load!
  end
end
