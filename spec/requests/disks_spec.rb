RSpec.describe "Disks API" do
  let(:hw) { FactoryBot.create(:hardware) }
  let(:vm) { FactoryBot.create(:vm_vmware, :hardware => hw) }
  let!(:disk) { FactoryBot.create(:disk, :hardware => hw) }

  describe "as a subcollection of VMs" do
    describe "GET /api/vms/:c_id/disks" do
      it "can list the snapshots of a VM" do
        api_basic_authorize(subcollection_action_identifier(:vms, :disks, :read, :get))

        _other_disk = FactoryBot.create(:disk)

        get(api_vm_disks_url(nil, vm))

        expected = {
          "count"     => 2,
          "name"      => "disks",
          "subcount"  => 1,
          "resources" => [
            {"href" => api_vm_disk_url(nil, vm, disk)}
          ]
        }

        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /api/vms/:c_id/disks/:s_id" do
      it "can show a VM's disk" do
        api_basic_authorize(subcollection_action_identifier(:vms, :disks, :read, :get))

        get(api_vm_disk_url(nil, vm, disk))

        expected = {
          "href" => api_vm_disk_url(nil, vm, disk),
          "id"   => disk.id.to_s,
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not show a disk unless authorized" do
        api_basic_authorize

        get(api_vm_disk_url(nil, vm, disk))
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
