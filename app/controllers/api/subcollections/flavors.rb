module Api
  module Subcollections
    module Flavors
      def flavors_query_resource(object)
        object.flavors
      end

      def flavors_create_resource(parent, _type, _id, data)
        task_id = Flavor.create_flavor_queue(User.current_user.id, parent, data)
        action_result(true, 'Creating Flavor', :task_id => task_id)
      rescue => err
        action_result(false, err.to_s)
      end

      def delete_resource_flavors(_parent, type, id, _data)
        flavor = resource_search(id, type, collection_class(type))
        task_id = flavor.delete_flavor_queue(User.current_user.id)
        action_result(true, "Deleting #{flavor_ident(flavor)}", :task_id => task_id)
      rescue => err
        action_result(false, err.to_s)
      end
      alias flavors_delete_resource delete_resource_flavors

      private

      def flavor_ident(flavor)
        "Flavor id:#{flavor.id} name: '#{flavor.name}'"
      end
    end
  end
end
