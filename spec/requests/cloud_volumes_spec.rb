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

    expected = {
      'message' => 'Deleting Cloud Volume CloudVolume1',
      'success' => true,
      'task_id' => a_kind_of(String)
    }

    expect(response.parsed_body).to include(expected)
    expect(response).to have_http_status(:ok)
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

    expected = {
      'results' => a_collection_containing_exactly(
        a_hash_including(
          'success' => true,
          'message' => a_string_including('Deleting Cloud Volume CloudVolume1'),
          'task_id' => a_kind_of(String)
        ),
        a_hash_including(
          'success' => true,
          'message' => a_string_including('Deleting Cloud Volume CloudVolume2'),
          'task_id' => a_kind_of(String)
        )
      )
    }
    post(api_cloud_volumes_url, :params => { :action => 'delete', :resources => [{ 'id' => cloud_volume1.id }, { 'id' => cloud_volume2.id }] })

    expect(response.parsed_body).to include(expected)
    expect(response).to have_http_status(:ok)
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
    it 'can safe delete cloud volumes which support safe_delete' do
      ems = FactoryBot.create(:ems_autosde, :name => "Autosde")
      volume = FactoryBot.create(:cloud_volume_autosde, :ext_management_system => ems, :name => "my_volume")
      api_basic_authorize(action_identifier(:cloud_volumes, :safe_delete, :resource_actions, :post))

      post(api_cloud_volume_url(nil, volume), :params => {"action" => "safe_delete"})

      expected = {
        "success" => true,
        "message" => "Deleting Cloud Volume my_volume"
      }

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'safe_delete will raise an error if the cloud volume does not support safe_delete' do
      ems    = FactoryBot.create(:ems_autosde, :name => "Autosde")
      volume = FactoryBot.create(:cloud_volume, :ext_management_system => ems, :name => "my_volume")
      api_basic_authorize(action_identifier(:cloud_volumes, :safe_delete, :resource_actions, :post))

      post(api_cloud_volume_url(nil, volume), :params => {"action" => "safe_delete"})

      expected = {
        "success" => false,
        "message" => "Feature not available/supported"
      }

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end

    it "can safe delete a cloud volume as a resource action" do
      ems = FactoryBot.create(:ems_autosde, :name => "Autosde")
      volume1 = FactoryBot.create(:cloud_volume_autosde, :ext_management_system => ems, :name => "my_volume")

      api_basic_authorize(action_identifier(:cloud_volumes, :safe_delete, :resource_actions, :post))
      post(api_cloud_volumes_url, :params => {"action" => "safe_delete", "resources" => [{"id" => volume1.id}]})

      expected1 = {
        "success" => true,
        "message" => "Deleting Cloud Volume #{volume1.name}",
      }

      expect(response.parsed_body["results"][0]).to include(expected1)
      expect(response.parsed_body.length).to eq 1
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'OPTIONS /api/cloud_volumes' do
    it 'returns a DDF schema for add when available via OPTIONS' do
      zone = FactoryBot.create(:zone)
      provider = FactoryBot.create(:ems_autosde, :zone => zone)

      allow(provider.class::CloudVolume).to receive(:params_for_create).and_return('foo')

      options(api_cloud_volumes_url, :params => {:ems_id => provider.id})
      options("#{api_cloud_volumes_url}?ems_id=#{provider.id}")

      expect(response.parsed_body['data']['form_schema']).to eq('foo')
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'OPTIONS /api/cloud_volumes/:id' do
    it 'returns a DDF schema for edit when available via OPTIONS' do
      zone = FactoryBot.create(:zone)
      provider = FactoryBot.create(:ems_autosde, :zone => zone)
      cloud_volume = FactoryBot.create(:cloud_volume_autosde, :ext_management_system => provider)

      allow(Rbac).to receive(:filtered_object).and_return(cloud_volume)
      expect(cloud_volume).to receive(:params_for_update).and_return('foo')
      options("#{api_cloud_volumes_url}/#{cloud_volume.id}")

      expect(response.parsed_body['data']['form_schema']).to eq('foo')
      expect(response).to have_http_status(:ok)
    end
  end
end
