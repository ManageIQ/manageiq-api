RSpec.describe "CD-ROMs API" do
  let(:hw) { FactoryBot.create(:hardware) }
  let(:vm) { FactoryBot.create(:vm_vmware, :hardware => hw) }
  let!(:cdrom) { FactoryBot.create(:disk, :hardware => hw, :device_type => 'cdrom') }
  describe "as a subcollection of VMs" do
    describe "GET /api/vms/:c_id/cdroms" do
      it "can list the CD-ROMs of a VM" do
        api_basic_authorize(subcollection_action_identifier(:vms, :cdroms, :read, :get))

        _other_disk = FactoryBot.create(:disk, :device_type => 'cdrom')

        get(api_vm_cdroms_url(nil, vm))

        expected = {
          "count"     => 2,
          "name"      => "cdroms",
          "subcount"  => 1,
          "resources" => [
            {"href" => api_vm_cdrom_url(nil, vm, cdrom)}
          ]
        }

        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /api/vms/:c_id/cdroms/:s_id" do
      it "can show a VM's CD-ROM" do
        api_basic_authorize(subcollection_action_identifier(:vms, :cdroms, :read, :get))

        get(api_vm_cdrom_url(nil, vm, cdrom))

        expected = {
          "href" => api_vm_cdrom_url(nil, vm, cdrom),
          "id"   => cdrom.id.to_s,
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not show a CD-ROM unless authorized" do
        api_basic_authorize

        get(api_vm_cdrom_url(nil, vm, cdrom))
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
