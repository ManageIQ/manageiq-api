module Api
  class HostAggregatesController < BaseController
    include Subcollections::Tags

    def create_resource(_type, _id, data = {})
      ext_management_system = resource_search(data.delete('ems_id'), :providers, collection_class(:providers))
      klass = ext_management_system.class_by_ems('HostAggregate')
      raise BadRequestError, klass.unsupported_reason(:create) unless klass.supports?(:create)

      task_id = klass.create_aggregate_queue(session[:userid], ext_management_system, data.symbolize_keys)
      action_result(true, "Creating Host Aggregate #{data['name']} for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def edit_resource(type, id, data = {})
      raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id

      host_aggregate = resource_search(id, type, collection_class(:host_aggregates))
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
