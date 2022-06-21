#
# REST API Request Tests - Cloud Volumes
#
# Regions primary collections:
#   /api/cloud_volumes
#
# Tests for:
# GET /api/cloud_volumes/:id
#

describe "Cloud Volumes API" do
  include Spec::Support::SupportsHelper

  it "forbids access to cloud volumes without an appropriate role" do
    api_basic_authorize

    get(api_cloud_volumes_url)

    expect(response).to have_http_status(:forbidden)
  end

  it "forbids access to a cloud volume resource without an appropriate role" do
    api_basic_authorize

    cloud_volume = FactoryBot.create(:cloud_volume)

    get(api_cloud_volume_url(nil, cloud_volume))

    expect(response).to have_http_status(:forbidden)
  end

  it "allows GETs of a cloud volume" do
    api_basic_authorize action_identifier(:cloud_volumes, :read, :resource_actions, :get)

    cloud_volume = FactoryBot.create(:cloud_volume)

    get(api_cloud_volume_url(nil, cloud_volume))

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(
      "href" => api_cloud_volume_url(nil, cloud_volume),
      "id"   => cloud_volume.id.to_s
    )
  end

  it "rejects delete request without appropriate role" do
    api_basic_authorize

    post(api_cloud_volumes_url, :params => { :action => 'delete' })

    expect(response).to have_http_status(:forbidden)
  end

  it "can delete a single cloud volume" do
    zone = FactoryBot.create(:zone, :name => "api_zone")
    aws = FactoryBot.create(:ems_amazon, :zone => zone)

    cloud_volume1 = FactoryBot.create(:cloud_volume, :ext_management_system => aws, :name => "CloudVolume1")

    api_basic_authorize action_identifier(:cloud_volumes, :delete, :resource_actions, :post)

    post(api_cloud_volume_url(nil, cloud_volume1), :params => { :action => "delete" })

    expect_single_action_result(:success => true, :task => true, :message => /Deleting Cloud Volume/)
  end

  it "can delete a cloud volume with DELETE as a resource action" do
    zone = FactoryBot.create(:zone, :name => "api_zone")
    aws = FactoryBot.create(:ems_amazon, :zone => zone)

    cloud_volume1 = FactoryBot.create(:cloud_volume, :ext_management_system => aws, :name => "CloudVolume1")

    api_basic_authorize action_identifier(:cloud_volumes, :delete, :resource_actions, :delete)

    delete api_cloud_volume_url(nil, cloud_volume1)

    expect(response).to have_http_status(:no_content)
  end

  it "rejects delete request with DELETE as a resource action without appropriate role" do
    cloud_volume = FactoryBot.create(:cloud_volume)

    api_basic_authorize

    delete api_cloud_volume_url(nil, cloud_volume)

    expect(response).to have_http_status(:forbidden)
  end

  it 'DELETE will raise an error if the cloud volume does not exist' do
    api_basic_authorize action_identifier(:cloud_volumes, :delete, :resource_actions, :delete)

    delete(api_cloud_volume_url(nil, 999_999))

    expect(response).to have_http_status(:not_found)
  end

  it 'can delete cloud volumes through POST' do
    zone = FactoryBot.create(:zone, :name => "api_zone")
    aws = FactoryBot.create(:ems_amazon, :zone => zone)

    cloud_volume1 = FactoryBot.create(:cloud_volume, :ext_management_system => aws, :name => "CloudVolume1")
    cloud_volume2 = FactoryBot.create(:cloud_volume, :ext_management_system => aws, :name => "CloudVolume2")

    api_basic_authorize collection_action_identifier(:cloud_volumes, :delete, :post)

    post(api_cloud_volumes_url, :params => { :action => 'delete', :resources => [{ 'id' => cloud_volume1.id }, { 'id' => cloud_volume2.id }] })
    expect_multiple_action_result(2, :task => true, :message => /Deleting Cloud Volume/)
  end

  it 'it can create cloud volumes through POST' do
    zone = FactoryBot.create(:zone, :name => "api_zone")
    provider = FactoryBot.create(:ems_autosde, :zone => zone)

    api_basic_authorize collection_action_identifier(:cloud_volumes, :create, :post)

    post(api_cloud_volumes_url, :params => {:ems_id => provider.id, :name => 'foo', :size => 1234})

    expected = {
      'results' => a_collection_containing_exactly(
        a_hash_including(
          'success' => true,
          'message' => a_string_including('Creating Cloud Volume')
        )
      )
    }

    expect(response.parsed_body).to include(expected)
    expect(response).to have_http_status(:ok)
  end

  describe "safe delete" do
    let(:ems) { FactoryBot.create(:ext_management_system) }
    let(:volume) { FactoryBot.create(:cloud_volume, :ext_management_system => ems) }

    context "with a volume that supports safe delete" do
      before { stub_supports(volume, :safe_delete) }

      it "can safe delete cloud volumes" do
        api_basic_authorize(action_identifier(:cloud_volumes, :safe_delete, :resource_actions, :post))

        post(api_cloud_volume_url(nil, volume), :params => {"action" => "safe_delete"})

        expect_single_action_result(:success => true, :task => true, :message => /Deleting Cloud Volume/)
      end

      it "can safe delete a cloud volume as a resource action" do
        api_basic_authorize(action_identifier(:cloud_volumes, :safe_delete, :resource_actions, :post))
        post(api_cloud_volumes_url, :params => {"action" => "safe_delete", "resources" => [{"id" => volume.id}]})

        expect_multiple_action_result(1, :success => true, :message => /Deleting Cloud Volume/)
      end
    end

    context "with a volume that does not support safe delete" do
      before { stub_supports_not(volume, :safe_delete) }

      it "safe_delete will raise an error if the cloud volume does not support safe_delete" do
        api_basic_authorize(action_identifier(:cloud_volumes, :safe_delete, :resource_actions, :post))

        post(api_cloud_volume_url(nil, volume), :params => {"action" => "safe_delete"})
        expect_bad_request(/Safe Delete for Cloud Volume.*not available/)
      end
    end
  end

  describe 'OPTIONS /api/cloud_volumes' do
    it 'returns a DDF schema for add when available via OPTIONS' do
      zone = FactoryBot.create(:zone)
      provider = FactoryBot.create(:ems_autosde, :zone => zone)

      stub_supports(provider.class::CloudVolume, :create)
      stub_params_for(provider.class::CloudVolume, :create, :fields => [])

      options(api_cloud_volumes_url(:ems_id => provider.id))

      expect(response.parsed_body['data']).to match("form_schema" => {"fields" => []})
      expect(response).to have_http_status(:ok)
    end

    it 'returns a DDF schema for attach cloud volume when available via OPTIONS' do
      zone = FactoryBot.create(:zone)
      provider = FactoryBot.create(:ems_autosde, :zone => zone)
      cloud_volume = FactoryBot.create(:cloud_volume_autosde, :ext_management_system => provider)

      stub_supports(cloud_volume.class, :attach)
      stub_params_for(cloud_volume.class, :attach, :fields => [])
      options(api_cloud_volume_url(nil, cloud_volume), :params => {"option_action" => "attach"})

      expect(response.parsed_body['data']).to match("form_schema" => {"fields" => []})
      expect(response).to have_http_status(:ok)
    end

    it 'returns no DDF schema for non supported actions via OPTIONS' do
      zone = FactoryBot.create(:zone)
      provider = FactoryBot.create(:ems_autosde, :zone => zone)
      cloud_volume = FactoryBot.create(:cloud_volume_autosde, :ext_management_system => provider)

      options(api_cloud_volume_url(nil, cloud_volume), :params => {"option_action" => "bogus"})

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'OPTIONS /api/cloud_volumes/:id' do
    it 'returns a DDF schema for edit when available via OPTIONS' do
      zone = FactoryBot.create(:zone)
      provider = FactoryBot.create(:ems_autosde, :zone => zone)
      cloud_volume = FactoryBot.create(:cloud_volume_autosde, :ext_management_system => provider)

      stub_supports(cloud_volume.class, :update)
      stub_params_for(cloud_volume.class, :update, :fields => [])
      options(api_cloud_volume_url(nil, cloud_volume))

      expect(response.parsed_body['data']).to match("form_schema" => {"fields" => []})
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'create backup' do
    it 'it can create cloud volume backup through POST' do
      zone = FactoryBot.create(:zone)
      provider = FactoryBot.create(:ems_autosde, :zone => zone)
      cloud_volume = FactoryBot.create(:cloud_volume_autosde, :ext_management_system => provider)

      api_basic_authorize(action_identifier(:cloud_volumes, :create_backup, :resource_actions, :post))
      stub_supports(cloud_volume.class, :backup_create)

      payload = {:action => "create_backup", :resources => {:backup_name => "stud_backup_name"}}
      post(api_cloud_volume_url(nil, cloud_volume), :params => payload)

      expect(response).to have_http_status(:ok)
    end

    it 'attaches Cloud Volume to an instance' do
      zone = FactoryBot.create(:zone)
      ems = FactoryBot.create(:ems_autosde, :zone => zone)
      vm = FactoryBot.create(:vm_vmware)
      cloud_volume = FactoryBot.create(:cloud_volume_autosde, :ext_management_system => ems)

      api_basic_authorize(action_identifier(:cloud_volumes, :attach, :resource_actions, :post))
      stub_supports(cloud_volume.class, :attach)

      payload = {:action => "attach", :resources => {:vm_id => vm.id.to_s}}
      post(api_cloud_volume_url(nil, cloud_volume), :params => payload)

      expect(response).to have_http_status(:ok)
    end

    it 'detaches Cloud Volume from an instance' do
      zone = FactoryBot.create(:zone)
      ems = FactoryBot.create(:ems_autosde, :zone => zone)
      hw = FactoryBot.create(:hardware)
      vm = FactoryBot.create(:vm_vmware, :hardware => hw)
      cloud_volume = FactoryBot.create(:cloud_volume_autosde, :ext_management_system => ems)
      FactoryBot.create(:disk, :hardware => hw, :backing => cloud_volume)

      api_basic_authorize(action_identifier(:cloud_volumes, :detach, :resource_actions, :post))
      stub_supports(cloud_volume.class, :detach)

      payload = {:action => "detach", :resources => {:vm_id => vm.id.to_s}}
      post(api_cloud_volume_url(nil, cloud_volume), :params => payload)

      expect(response).to have_http_status(:ok)
    end

    it 'attach raise an error if the cloud volume does not support attach' do
      cloud_volume = FactoryBot.create(:cloud_volume_autosde)
      stub_supports_not(:cloud_volume, :attach)

      api_basic_authorize(action_identifier(:cloud_volumes, :attach, :resource_actions, :post))

      post(api_cloud_volume_url(nil, cloud_volume), :params => {:action => "attach"})
      expected = {
        "success" => false,
        "message" => a_string_including("Attach for Cloud Volume id: #{cloud_volume.id} name: '': Feature not available\/supported")
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end

    it 'detach raise an error if the cloud volume does not support detach' do
      cloud_volume = FactoryBot.create(:cloud_volume_autosde)
      stub_supports_not(:cloud_volume, :detach)

      api_basic_authorize(action_identifier(:cloud_volumes, :detach, :resource_actions, :post))

      post(api_cloud_volume_url(nil, cloud_volume), :params => {:action => "detach"})
      expected = {
        "success" => false,
        "message" => a_string_including("Detach for Cloud Volume id: #{cloud_volume.id} name: '': Feature not available\/supported")
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'restore backup' do
    it 'it can restore cloud volume backup through POST' do
      zone = FactoryBot.create(:zone)
      provider = FactoryBot.create(:ems_autosde, :zone => zone)
      cloud_volume = FactoryBot.create(:cloud_volume_autosde, :ext_management_system => provider)

      api_basic_authorize(action_identifier(:cloud_volumes, :restore_backup, :resource_actions, :post))
      stub_supports(cloud_volume.class, :backup_restore)

      payload = {:action => "restore_backup", :resources => {:backup_id => 1}}
      post(api_cloud_volume_url(nil, cloud_volume), :params => payload)

      expect(response).to have_http_status(:ok)
    end

    describe 'clone cloud volume' do
      it 'clones a Cloud Volume' do
        zone = FactoryBot.create(:zone)
        ems = FactoryBot.create(:ems_autosde, :zone => zone)
        cloud_volume = FactoryBot.create(:cloud_volume_autosde, :ext_management_system => ems)

        api_basic_authorize(action_identifier(:cloud_volumes, :clone, :resource_actions, :post))
        stub_supports(cloud_volume.class, :clone)

        payload = {:action => "clone", :resources => {:name => 'TestClone'}}
        post(api_cloud_volume_url(nil, cloud_volume), :params => payload)

        expect(response).to have_http_status(:ok)
      end

      it 'clone raises an error if the cloud volume does not support clone' do
        cloud_volume = FactoryBot.create(:cloud_volume_autosde)
        stub_supports_not(:cloud_volume, :clone)

        api_basic_authorize(action_identifier(:cloud_volumes, :clone, :resource_actions, :post))

        post(api_cloud_volume_url(nil, cloud_volume), :params => {:action => "clone"})
        expected = {
          "success" => false,
          "message" => a_string_including("Clone for Cloud Volume id: #{cloud_volume.id} name: '': Feature not available\/supported")
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:bad_request)
      end

      let(:invalid_cloud_volume_url) { api_cloud_volume_url(nil, ApplicationRecord.id_in_region(999_999, ApplicationRecord.my_region_number)) }
      it "to a valid cloud volume without appropriate role" do
        api_basic_authorize

        post(invalid_cloud_volume_url, :params => gen_request(:clone, "name" => "test"))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
