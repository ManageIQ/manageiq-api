#
# REST API Request Tests - Cloud Volume Types
#
# Regions primary collections:
#   /api/cloud_volume_types
#
# Tests for:
# GET /api/cloud_volume_types/:id
#

describe "Cloud Volume Types API" do
  context "collection access" do
    it "forbids access to cloud volume types without an appropriate role" do
      api_basic_authorize
      get(api_cloud_volume_types_url)
      expect(response).to have_http_status(:forbidden)
    end

    it "allows access to cloud volume types with an appropriate role" do
      api_basic_authorize action_identifier(:cloud_volume_types, :read, :collection_actions, :get)
      instance = CloudVolumeType.create!
      get(api_cloud_volume_types_url)
      expect(response).to have_http_status(:ok)
      url = api_cloud_volume_type_url(nil, instance)
      expect(response.parsed_body["resources"]).to include("href" => url)
    end
  end

  context "resource access" do
    it "forbids access to a cloud volume type resource without an appropriate role" do
      api_basic_authorize
      instance = CloudVolumeType.create!
      get(api_cloud_volume_type_url(nil, instance))
      expect(response).to have_http_status(:forbidden)
    end

    it "allows access to a cloud volume type resource with an appropriate role" do
      api_basic_authorize action_identifier(:cloud_volume_types, :read, :resource_actions, :get)
      instance = CloudVolumeType.create!
      url = api_cloud_volume_type_url(nil, instance)
      get(url)
      expect(response.parsed_body).to include(
        "href" => url,
        "id"   => instance.id.to_s
      )
    end
  end
end
