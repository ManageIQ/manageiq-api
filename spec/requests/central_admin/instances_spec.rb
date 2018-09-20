describe "/api/instances central admin" do
  let(:resource_type) { "instance" }

  include_examples "resource power operations", :vm_amazon, :pause
  include_examples "resource power operations", :vm_amazon, :reboot_guest
  include_examples "resource power operations", :vm_amazon, :reset
  include_examples "resource power operations", :vm_amazon, :shelve
  include_examples "resource power operations", :vm_amazon, :start
  include_examples "resource power operations", :vm_amazon, :stop
  include_examples "resource power operations", :vm_amazon, :suspend
  include_examples "resource power operations", :vm_amazon, :terminate
end
