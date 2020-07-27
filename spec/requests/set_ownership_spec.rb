#
# Rest API Request Tests - set_ownership action specs
#
# set_ownership action availability to:
# - Services                /api/services/:id
# - Vms                     /api/vms/:id
# - Templates               /api/templates/:id
#
describe "Set Ownership" do
  RESOURCES = {:services => :service, :vms => :vm, :templates => :template_vmware}.freeze

  RESOURCES.each do |collection_name, factory_name|
    it_behaves_like "endpoints with set_ownership action", collection_name, factory_name
  end
end
