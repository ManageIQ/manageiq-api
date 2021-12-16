RSpec.describe "CloudVolumeSnapshots API" do
  describe "as a subcollection of cloud volumes" do
    describe "GET /api/cloud_volumes/:c_id/cloud_volume_snapshots" do
      it "can list the cloud volume snapshots of an cloud_volumes" do
        api_basic_authorize(subcollection_action_identifier(:cloud_volumes, :cloud_volume_snapshots, :read, :get))
        cloud_volume = FactoryBot.create(:cloud_volume)
        cloud_volume_snapshot = FactoryBot.create(:cloud_volume_snapshot, :cloud_volume => cloud_volume)
        other_snapshot = FactoryBot.create(:cloud_volume_snapshot)
        get(api_cloud_volume_cloud_volume_snapshots_url(nil, cloud_volume))
        expected = {
          "count"     => 2,
          "name"      => "cloud_volume_snapshots",
          "subcount"  => 1,
          "resources" => [{
            "href" => api_cloud_volume_cloud_volume_snapshot_url(nil, cloud_volume, cloud_volume_snapshot)
          }]
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "will not list cloud volume snapshots unless authorized" do
        api_basic_authorize
        cloud_volume = FactoryBot.create(:cloud_volume)
        FactoryBot.create(:cloud_volume_snapshot, :cloud_volume => cloud_volume)

        get(api_cloud_volume_cloud_volume_snapshots_url(nil, cloud_volume))

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET /api/cloud_volumes/:c_id/cloud_volume_snapshots" do
      it "can show a cloud volume snapshot" do
        api_basic_authorize(subcollection_action_identifier(:cloud_volumes, :cloud_volume_snapshots, :read, :get))
        cloud_volume = FactoryBot.create(:cloud_volume)
        cloud_volume_snapshot = FactoryBot.create(:cloud_volume_snapshot, :cloud_volume => cloud_volume)
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
        cloud_volume = FactoryBot.create(:cloud_volume)
        cloud_volume_snapshot = FactoryBot.create(:cloud_volume_snapshot, :cloud_volume => cloud_volume)

        get(api_cloud_volume_cloud_volume_snapshot_url(nil, cloud_volume, cloud_volume_snapshot))

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /api/cloud_volumes/:c_id/cloud_volume_snapshots" do
      it "can queue the creation of a cloud volume snapshot" do
        api_basic_authorize(subcollection_action_identifier(:cloud_volumes, :cloud_volume_snapshots, :create))
        cloud_volume = FactoryBot.create(:cloud_volume)
        post(api_cloud_volume_cloud_volume_snapshots_url(nil, cloud_volume), :params => {:name => "Alice's cloud volume snapshot"})

        expected = {
          "results" => [
            a_hash_including(
              "success"   => true,
              "message"   => "Creating snapshot Alice's cloud volume snapshot for Cloud Volume id:#{cloud_volume.id} name:'Alice's VM'",
              "task_id"   => anything,
              "task_href" => a_string_matching(api_tasks_url)
            )
          ]
        }
        expect_single_action_result(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end

      it "renders a failed action response if cloud volume snapshotting is not supported" do
        api_basic_authorize(subcollection_action_identifier(:cloud_volumes, :cloud_volume_snapshots, :create))
        cloud_volume = FactoryBot.create(:cloud_volume)

        post(api_cloud_volume_cloud_volume_snapshots_url(nil, cloud_volume), :params => {:name => "Alice's snapshot"})

        expected = {
          "results" => [
            a_hash_including(
              "success" => false,
              "message" => "The Cloud Volume is not connected to an active Provider"
            )
          ]
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
