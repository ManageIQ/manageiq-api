require "config"

module Api
  ::Config.overwrite_arrays = false
  ApiConfig = ::Config::Options.new.tap do |o|
    Vmdb::Plugins.each { |plugin| o.add_source!(plugin.root.join('config/api.yml').to_s) }
    o.add_source!(ManageIQ::Api::Engine.root.join("config/api.yml").to_s)
    o.load!
  end
end
