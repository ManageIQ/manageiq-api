namespace :spec do
  desc "Setup environment specs"
  task :setup => ["app:test:vmdb:setup"]

  desc "Run security specs from core"
  task :security => ["app:test:security"]
end

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec => 'app:test:spec_deps') do |t|
  EvmTestHelper.init_rspec_task(t)
end
