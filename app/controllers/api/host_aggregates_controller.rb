module Api
  class HostAggregatesController < BaseController
    include Subcollections::Tags

    def create_resource(type, _id, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, klass|
        {:task_id => klass.create_aggregate_queue(User.current_userid, ems, data)}
      end
    end

    def edit_resource(type, id, data = {})
      raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id

      host_aggregate = resource_search(id, type)
      raise "Edit not supported for #{host_aggregate.name}" unless host_aggregate.supports?(:update)

      task_id = host_aggregate.update_aggregate_queue(current_user.userid, data.symbolize_keys)
      action_result(true, "Updating #{host_aggregate_ident(host_aggregate)}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource_main_action(_type, host_aggregate, _data = {})
      # TODO: ensure_supports(host_aggrtegate, :delete)
      {:task_id => host_aggregate.delete_aggregate_queue(current_user.userid)}
    end

    private

    def host_aggregate_ident(host_aggregate)
      "Host Aggregate id:#{host_aggregate.id} name: '#{host_aggregate.name}'"
    end
  end
end
