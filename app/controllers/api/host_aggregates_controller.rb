module Api
  class HostAggregatesController < BaseController
    include Subcollections::Tags

    def create_resource(type, _id, data = {})
      create_ems_resource(type, data, :supports => true) do |ems, klass|
        {:task_id => klass.create_aggregate_queue(User.current_userid, ems, data)}
      end
    end

    def edit_resource(type, id, data = {})
      api_resource(type, id, "Updating", :supports => :update) do |host_aggregate|
        {:task_id => host_aggregate.update_aggregate_queue(User.current_userid, data.deep_symbolize_keys)}
      end
    end

    def delete_resource_main_action(_type, host_aggregate, _data = {})
      # TODO: ensure_supports(host_aggrtegate, :delete)
      {:task_id => host_aggregate.delete_aggregate_queue(current_user.userid)}
    end

    def add_host_resource(type, id, data = {})
      api_resource(type, id, "Adding Host to", :supports => :add_host) do |host_aggregate|
        new_host = lookup_host(data["host_id"])
        {:task_id => host_aggregate.add_host_queue(User.current_userid, new_host)}
      end
    end

    def remove_host_resource(type, id, data = {})
      api_resource(type, id, "Removing Host from", :supports => :remove_host) do |host_aggregate|
        new_host = lookup_host(data["host_id"])
        {:task_id => host_aggregate.remove_host_queue(User.current_userid, new_host)}
      end
    end

    private

    def lookup_host(host_id)
      raise BadRequestError, "Must specify a host_id" if host_id.nil?

      resource_search(host_id, :hosts)
    end
  end
end
