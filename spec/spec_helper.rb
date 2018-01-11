if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require 'manageiq-api'

Dir[ManageIQ::Api::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include Spec::Support::Api::Helpers, :type => :request
  config.include Spec::Support::Api::RequestHelpers, :type => :request
  config.define_derived_metadata(:type => :request) do |metadata|
    metadata[:aggregate_failures] = true
  end

  config.before(:each, :type => :request) { init_api_spec_env unless User.count > 0 }
end
