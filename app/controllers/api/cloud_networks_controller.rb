module Api
  class CloudNetworksController < BaseController
    include Subcollections::Tags

    def delete_resource(type, resource_id, _data = {})
      raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless resource_id

      cloud_network = resource_search(resource_id, type, collection_class(type))
      task_id = cloud_network.delete_cloud_network_queue(User.current_user.userid)
      action_result(true, "Deleting #{cloud_network.name}", :task_id => task_id)
    end
  end
end
