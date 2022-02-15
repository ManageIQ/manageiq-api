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

    def add_host_resource(type, id, data = {})
      raise BadRequestError, "Must specify an id" if id.nil?
      raise BadRequestError, "Must specify a host_id" if data["host_id"].nil?

      host_aggregate = resource_search(id, type)
      raise BadRequestError, host_aggregate.unsupported_reason(:add_host) unless host_aggregate.supports?(:add_host)

      new_host = resource_search(data["host_id"], :hosts)
      task_id = host_aggregate.add_host_queue(current_user.userid, new_host)
      action_result(true, "Adding #{host_aggregate_ident(host_aggregate)}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def remove_host_resource(type, id, data = {})
      raise BadRequestError, "Must specify an id" if id.nil?
      raise BadRequestError, "Must specify a host_id" if data["host_id"].nil?

      host_aggregate = resource_search(id, type)
      raise BadRequestError, host_aggregate.unsupported_reason(:remove_host) unless host_aggregate.supports?(:remove_host)

      new_host = resource_search(data["host_id"], :hosts)
      task_id = host_aggregate.remove_host_queue(current_user.userid, new_host)
      action_result(true, "Removing #{host_aggregate_ident(host_aggregate)}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    private

    def host_aggregate_ident(host_aggregate)
      "Host Aggregate id:#{host_aggregate.id} name: '#{host_aggregate.name}'"
    end
  end
end
