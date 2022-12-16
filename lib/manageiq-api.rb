
require "zeitwerk"
loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.ignore(__FILE__)

# Add non-standard root directory to the path
loader.push_dir("#{__dir__}/../app/controllers")

# This tells the loader to not expect Services namespace
loader.collapse("#{__dir__}/services")

loader.ignore("#{__dir__}/api/api_config.rb")  # Dynamically loads all Vmdb::Plugins - assumes we're mounted in manageiq

# These inflectors teach the loader our naming convention here
loader.inflector.inflect(
  "manageiq"  => "ManageIQ",
  "version"   => "VERSION",  # TODO: why is this needed, for_gem is supposed to do this
)

loader.setup

# TODO: consider turning on eager_load and only disable really slow/fat requires
# loader.eager_load

require "manageiq/api"
