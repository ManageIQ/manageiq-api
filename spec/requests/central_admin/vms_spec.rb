describe "/api/vms central admin" do
  let(:resource_type) { "vm" }

  include_examples "resource power operations", :vm_vmware, :pause
  include_examples "resource power operations", :vm_vmware, :reboot_guest
  include_examples "resource power operations", :vm_vmware, :refresh
  include_examples "resource power operations", :vm_vmware, :reset
  include_examples "resource power operations", :vm_vmware, :scan
  include_examples "resource power operations", :vm_vmware, :shelve
  include_examples "resource power operations", :vm_vmware, :shelve_offload
  include_examples "resource power operations", :vm_vmware, :shutdown_guest
  include_examples "resource power operations", :vm_vmware, :start
  include_examples "resource power operations", :vm_vmware, :stop
  include_examples "resource power operations", :vm_vmware, :suspend
end
