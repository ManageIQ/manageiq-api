# desc "Explaining what the task does"
# task :manageiq_api do
#   # Task goes here
# end

namespace "manageiq:api" do
  desc "Generate an OpenAPI specification"
  task "openapi_generate" => :environment do
    generator = ManageIQ::Api::OpenApi::Generator.new
    generator.generate!
  end
end
