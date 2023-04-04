RSpec.describe "CloudVolumeSnapshots API" do
  include Spec::Support::SupportsHelper

  let(:ems) { FactoryBot.create(:ems_cinder) }
  let(:cloud_volume) { FactoryBot.create(:cloud_volume_openstack, :ext_management_system => ems) }
  let(:cloud_volume_snapshot) { FactoryBot.create(:cloud_volume_snapshot_openstack, :cloud_volume => cloud_volume, :ext_management_system => ems) }

  describe "as a subcollection of cloud volumes" do
    describe "GET /api/cloud_volumes/:c_id/cloud_volume_snapshots" do
      it "can list the cloud volume snapshots of an cloud_volumes" do
        api_basic_authorize(subcollection_action_identifier(:cloud_volumes, :cloud_volume_snapshots, :read, :get))

        cloud_volume_snapshot
        FactoryBot.create(:cloud_volume_snapshot)

        get(api_cloud_volume_cloud_volume_snapshots_url(nil, cloud_volume))
        expected = {
          "count"     => 2,
          "name"      => "cloud_volume_snapshots",
          "subcount"  => 1,
          "resources" => [
            {"href" => api_cloud_volume_cloud_volume_snapshot_url(nil, cloud_volume, cloud_volume_snapshot)}
          ]
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not list cloud volume snapshots unless authorized" do
        api_basic_authorize

        cloud_volume_snapshot
        get(api_cloud_volume_cloud_volume_snapshots_url(nil, cloud_volume))

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET /api/cloud_volumes/:c_id/cloud_volume_snapshots" do
      it "can show a cloud volume snapshot" do
        api_basic_authorize(subcollection_action_identifier(:cloud_volumes, :cloud_volume_snapshots, :read, :get))

        get(api_cloud_volume_cloud_volume_snapshot_url(nil, cloud_volume, cloud_volume_snapshot))
        expected = {
          "id"   => cloud_volume_snapshot.id.to_s,
          "href" => api_cloud_volume_cloud_volume_snapshot_url(nil, cloud_volume, cloud_volume_snapshot)
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not show a cloud volume snapshot unless authorized" do
        api_basic_authorize

        get(api_cloud_volume_cloud_volume_snapshot_url(nil, cloud_volume, cloud_volume_snapshot))

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /api/cloud_volumes/:c_id/cloud_volume_snapshots" do
      it "can queue the creation of a cloud volume snapshot" do
        api_basic_authorize(subcollection_action_identifier(:cloud_volumes, :cloud_volume_snapshots, :create))
        stub_supports(CloudVolumeSnapshot, :create)

        post(api_cloud_volume_cloud_volume_snapshots_url(nil, cloud_volume), :params => {:name => "new snapshot"})

        expect_multiple_action_result(1, :success => true, :message => "Creating cloud volume snapshot")
      end

      it "renders a failed action response if cloud volume snapshotting is not supported" do
        api_basic_authorize(subcollection_action_identifier(:cloud_volumes, :cloud_volume_snapshots, :create))
        stub_supports_not(ems.class_by_ems(:CloudVolumeSnapshot), :create)

        post(api_cloud_volume_cloud_volume_snapshots_url(nil, cloud_volume), :params => {:name => "Alice's snapshot"})

        expect_bad_request(/Feature not .*supported/)
      end
    end

    describe "DELETE /api/cloud_volumes/:c_id/cloud_volume_snapshots/:s_id" do
      it "create & delete cloud volume snapshot" do
        api_basic_authorize('cloud_volume_snapshot_delete')

        stub_supports(CloudVolumeSnapshot, :delete)
        post(api_cloud_volume_snapshot_url(nil, cloud_volume_snapshot), :params => gen_request(:delete))

        expect_single_action_result(:success => true, :message => /Deleting Cloud Volume Snapshot id: #{cloud_volume_snapshot.id} name: '#{cloud_volume_snapshot.name}'/)
      end
    end
  end
end
