module Api
  class CloudVolumesController < BaseController
    include Subcollections::Tags

    def delete_resource(type, id, _data = {})
      delete_action_handler do
        cloud_volume = resource_search(id, type, collection_class(:cloud_volumes))
        task_id = cloud_volume.delete_volume_queue(User.current_user)
        action_result(true, "Deleting Cloud Volume #{cloud_volume.name}", :task_id => task_id)
      end
    end
  end
end
