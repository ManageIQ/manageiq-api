module Api
  module Subcollections
    module CloudNetworks
      def cloud_networks_query_resource(object)
        object.respond_to?(:cloud_networks) ? Array(object.cloud_networks) : []
      end

      def cloud_networks_create_resource(provider, _type, _id, data)
        begin
          data.deep_symbolize_keys!
          raise 'Must specify a name for the cloud network' unless data[:name]

          message = "Creating cloud network"
          task_id = queue_object_action(provider, message, :method_name => "create_cloud_network", :args => [data])
          action_result(true, message, :task_id => task_id)
        rescue => e
          action_result(false, e.to_s)
        end
      end

      def cloud_networks_edit_resource(_object, type, id = nil, data = {})
        data.deep_symbolize_keys!
        raise BadRequestError, "Must specify an id for updating a #{type} resource" unless id

        cloud_network = resource_search(id, type, collection_class(type))
        task_id = cloud_network.update_cloud_network_queue(User.current_user.userid, data)
        action_result(true, "Updating #{cloud_network.name}", :task_id => task_id)
      end

      def cloud_networks_delete_resource(_parent, type, id, _data)
        raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless id

        cloud_network = resource_search(id, type, collection_class(type))
        task_id = cloud_network.delete_cloud_network_queue(User.current_user.userid)
        action_result(true, "Deleting #{cloud_network.name}", :task_id => task_id)
      end
    end
  end
end
