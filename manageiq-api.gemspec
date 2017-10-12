$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "manageiq/api/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "manageiq-api"
  s.version     = ManageIQ::Api::VERSION
  s.authors     = ["ManageIQ Developers"]
  s.homepage    = "https://github.com/ManageIQ/manageiq-api"
  s.summary     = "The ManageIQ Api"
  s.description = "The ManageIQ Api"
  s.licenses    = ["Apache-2.0"]

  s.files = Dir["{app,lib}/**/*", "LICENSE.txt", "Rakefile", "README.md"]

  s.add_dependency "config"
  s.add_dependency "jbuilder", "~> 2.5"

  s.add_development_dependency "codeclimate-test-reporter", "~> 1.0.0"
  s.add_development_dependency "simplecov"
end
