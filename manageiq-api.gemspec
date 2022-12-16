# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/api/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-api"
  spec.version       = ManageIQ::Api::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "ManageIQ API"
  spec.description   = "ManageIQ API"
  spec.homepage      = "https://github.com/ManageIQ/manageiq-api"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "config"
  # 2.9.0 regressed serialization
  # See: https://github.com/rails/jbuilder/issues/461
  spec.add_dependency "jbuilder", "~> 2.5", "!= 2.9.0"
  spec.add_dependency "multi_json"
  spec.add_dependency "rails"
  spec.add_dependency "responders"

  spec.add_development_dependency "codeclimate-test-reporter", "~> 1.0.0"
  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "simplecov", ">= 0.21.2"
end
