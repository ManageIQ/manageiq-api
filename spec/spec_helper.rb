if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require 'manageiq-api'

Dir[ManageIQ::Api::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include Spec::Support::ApiHelper, :type => :request
  config.define_derived_metadata(:type => :request) do |metadata|
    metadata[:aggregate_failures] = true
  end

  #TODO: Remove the conditional once the repo is split and the test checkout of manageiq
  # is guaranteed to no longer 'also' call init_api_spec_env.
  config.before(:each, :type => :request) { init_api_spec_env unless User.count > 0 }
end
