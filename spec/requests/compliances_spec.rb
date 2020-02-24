RSpec.describe "Compliances API" do
  let(:vm) { FactoryBot.create(:vm_vmware) }
  let!(:compliance) { FactoryBot.create(:compliance, :resource => vm) }
  let!(:compliance_detail) { FactoryBot.create(:compliance_detail, :compliance_id => compliance.id) }

  describe "as a subcollection of VMs" do
    describe "GET /api/vms/:c_id/compliances" do
      it "can list the compliances of a VM" do
        api_basic_authorize("vm_show")

        _other_compliance = FactoryBot.create(:compliance)

        get(api_vm_compliances_url(nil, vm))

        expected = {
          "count"     => 2,
          "name"      => "compliances",
          "subcount"  => 1,
          "resources" => [
            {"href" => api_vm_compliance_url(nil, vm, compliance)}
          ]
        }

        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "can list the details of compliances" do
        api_basic_authorize("vm_show")

        get(api_vm_compliances_url(nil, vm), :params => {:expand => 'resources', :attributes => 'compliance_details'})

        expected = {
          "count"     => 1,
          "name"      => "compliances",
          "subcount"  => 1,
          "resources" => [a_hash_including("compliance_details" => [a_hash_including("compliance_id"=>compliance.id.to_s)])]
        }

        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /api/vms/:c_id/compliances/:s_id" do
      it "can show a VM's compliances" do
        api_basic_authorize("vm_show")

        get(api_vm_compliance_url(nil, vm, compliance))

        expected = {
          "href" => api_vm_compliance_url(nil, vm, compliance),
          "id"   => compliance.id.to_s,
        }

        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "can show a VM's compliance details" do
        api_basic_authorize("vm_show")

        get(api_vm_compliance_url(nil, vm, compliance), :params => {:expand => 'resources', :attributes => 'compliance_details'})

        expected = {
          "href"               => api_vm_compliance_url(nil, vm, compliance),
          "id"                 => compliance.id.to_s,
          "compliance_details" => [a_hash_including("compliance_id" => compliance.id.to_s)]
        }

        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not show a compliance unless authorized" do
        api_basic_authorize

        get(api_vm_compliance_url(nil, vm, compliance))
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
