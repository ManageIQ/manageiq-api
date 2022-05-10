module Api
  module Subcollections
    module CloudVolumeSnapshots
      def cloud_volume_snapshots_query_resource(object)
        object.cloud_volume_snapshots
      end

      def cloud_volume_snapshots_create_resource(parent, type, _id, data)
        api_action(type, nil) do
          klass = parent.ext_management_system.class_by_ems(:CloudVolumeSnapshot)
          ensure_supports(type, klass, :create)
          message = "Creating cloud volume snapshot #{data["name"]} for #{model_ident(parent, :cloud_volumes)}"
          task_id = klass.create_snapshot_queue(User.current_userid, parent, data.symbolize_keys)

          action_result(true, message, :task_id => task_id)
        end
      end

      def update_resource_cloud_volume_snapshots(_parent, type, id, data)
        api_resource(type, id, "Updating", :supports => :update) do |cloud_volume_snapshot|
          {:task_id => cloud_volume_snapshot.update_cloud_volume_queue(User.current_userid, data.symbolize_keys)}
        end
      end
      alias cloud_volume_snapshots_update_resource update_resource_cloud_volume_snapshots

      def delete_resource_cloud_volume_snapshots(_parent, type, id, _data)
        api_resource(type, id, "Deleting", :supports => :delete) do |cloud_volume_snapshot|
          {:task_id => cloud_volume_snapshot.delete_cloud_volume_queue(User.current_userid)}
        end
      end
      alias cloud_volume_snapshots_delete_resource delete_resource_cloud_volume_snapshots

      def cloud_volume_snapshots_subcollection_options(parent)
        raise BadRequestError, "No DDF specified for cloud volume snapshots in #{parent}" unless parent.respond_to?(:params_for_create_cloud_volume_snapshot)

        {:cloud_volume_snapshot_form_schema => parent.params_for_create_cloud_volume_snapshot}
      end
    end
  end
end
