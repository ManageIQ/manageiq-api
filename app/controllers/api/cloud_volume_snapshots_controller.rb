module Api
  class CloudVolumeSnapshotsController < BaseController
    def delete_resource_action(type, id = nil, _data = nil)
      api_resource(type, id, "Deleting", :supports => :delete) do |snapshot|
        {:task_id => snapshot.delete_snapshot_queue(User.current_userid)}
      end
    end
  end
end
