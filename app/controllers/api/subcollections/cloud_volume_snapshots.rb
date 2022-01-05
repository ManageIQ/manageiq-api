module Api
  module Subcollections
    module CloudVolumeSnapshots
      def cloud_volume_snapshots_query_resource(object)
        object.cloud_volume_snapshots
      end

      def cloud_volume_snapshots_create_resource(parent, _type, _id, data)
        raise parent.unsupported_reason(:cloud_volume_snapshot_create) unless parent.supports?(:cloud_volume_snapshot_create)

        message = "Creating cloud volume snapshot #{data["name"]} for #{cloud_volume_snapshot_ident(parent)}"
        task_id = queue_object_action(
          parent,
          message,
          :method_name => "create_cloud_volume_snapshot",
          :args        => [data["name"], data["description"], data.fetch("memory", false)]
        )

        action_result(true, message, :task_id => task_id)
      rescue => e
        action_result(false, e.to_s)
      end

      def delete_resource_cloud_volume_snapshots(parent, type, id, _data)
        cloud_volume_snapshot = resource_search(id, type)
        begin
          raise parent.unsupported_reason(:remove_cloud_volume_snapshot) unless parent.supports?(:remove_cloud_volume_snapshot)

          message = "Deleting cloud volume snapshot #{cloud_volume_snapshot.name} for #{model_ident(parent, type)}"
          task_id = queue_object_action(parent, message, :method_name => "remove_cloud_volume_snapshot", :args => [id])
          action_result(true, message, :task_id => task_id)
        rescue => e
          action_result(false, e.to_s)
        end
      end
      alias cloud_volume_snapshots_delete_resource delete_resource_cloud_volume_snapshots

      def cloud_volume_snapshots_revert_resource(parent, type, id, _data)
        raise parent.unsupported_reason(:revert_to_cloud_volume_snapshot) unless parent.supports?(:revert_to_cloud_volume_snapshot)

        cloud_volume_snapshot = resource_search(id, type)

        message = "Reverting to cloud volume snapshot #{cloud_volume_snapshot.name} for #{cloud_volume_snapshot_ident(parent)}"
        task_id = queue_object_action(parent, message, :method_name => "revert_to_cloud_volume_snapshot", :args => [id])
        action_result(true, message, :task_id => task_id)
      rescue => e
        action_result(false, e.to_s)
      end

      def cloud_volume_snapshots_subcollection_options(parent)
        raise BadRequestError, "No DDF specified for cloud volume snapshots in #{parent}" unless parent.respond_to?(:params_for_create_cloud_volume_snapshot)

        {:cloud_volume_snapshot_form_schema => parent.params_for_create_cloud_volume_snapshot}
      end

      private

      def cloud_volume_snapshot_ident(parent)
        parent_ident = collection_config[@req.collection].description.singularize
        "#{parent_ident} id:#{parent.id} name:'#{parent.name}'"
      end
    end
  end
end
