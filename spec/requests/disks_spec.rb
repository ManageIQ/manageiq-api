RSpec.describe "Disks API" do
  let(:hw) { FactoryBot.create(:hardware) }
  let(:vm) { FactoryBot.create(:vm_vmware, :hardware => hw) }
  let!(:disk) { FactoryBot.create(:disk, :hardware => hw) }

  describe "as a subcollection of Templates" do
    let(:template_hw) { FactoryBot.create(:hardware) }
    let(:template) { FactoryBot.create(:template_vmware, :hardware => template_hw) }
    let!(:template_disk) { FactoryBot.create(:disk, :hardware => template_hw) }

    describe "GET /api/templates/:c_id/disks" do
      it "can list the disks of a Template" do
        api_basic_authorize(subcollection_action_identifier(:templates, :disks, :read, :get))

        _other_disk = FactoryBot.create(:disk)

        get(api_template_disks_url(nil, template))

        expected = {
          "count"     => 3,
          "name"      => "disks",
          "subcount"  => 1,
          "resources" => [
            {"href" => api_template_disk_url(nil, template, template_disk)}
          ]
        }

        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /api/templates/:c_id/disks/:s_id" do
      it "can show a Template's disk" do
        api_basic_authorize(subcollection_action_identifier(:templates, :disks, :read, :get))

        get(api_template_disk_url(nil, template, template_disk))

        expected = {
          "href" => api_template_disk_url(nil, template, template_disk),
          "id"   => template_disk.id.to_s,
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not show a disk unless authorized" do
        api_basic_authorize

        get(api_template_disk_url(nil, template, template_disk))
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

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
