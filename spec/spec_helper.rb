if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require 'manageiq-api'

Dir[ManageIQ::Api::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
