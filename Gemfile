source 'https://rubygems.org'

gemspec

# Load Gemfile with dependencies from manageiq
manageiq_gemfile = File.expand_path("spec/manageiq/Gemfile", __dir__)
if File.exist?(manageiq_gemfile)
  eval_gemfile(manageiq_gemfile)
else
  puts "ERROR: The ManageIQ application must be present in spec/manageiq."
  puts "  Clone it from GitHub or symlink it from local source."
  exit 1
end

# Load other additional Gemfiles
#   Developers can create a file ending in .rb under bundler.d/ to specify additional development dependencies
Dir.glob(File.join(__dir__, 'bundler.d/*.rb')).each { |f| eval_gemfile(File.expand_path(f, __dir__)) }
