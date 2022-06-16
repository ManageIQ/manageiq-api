module Api
  class PhysicalStoragesController < BaseController
    def refresh_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Refreshing", :method_name => :refresh_ems)
    end

    def create_resource(type, _id = nil, data = {})
      # TODO: introduce supports for ems specific physical storage
      create_ems_resource(type, data) do |ems, klass|
        {:task_id => klass.create_physical_storage_queue(User.current_userid, ems, data)}
      end
    end

    def edit_resource(type, id, data = {})
      api_resource(type, id, "Updating", :supports => :update) do |physical_storage|
        {:task_id => physical_storage.update_physical_storage_queue(User.current_userid, data)}
      end
    end

    def delete_resource_action(type, id = nil, _data = nil)
      api_resource(type, id, "Detaching", :supports => :delete) do |physical_storage|
        {:task_id => physical_storage.delete_physical_storage_queue(User.current_user)}
      end
    end

    def validate_resource(type, id = nil, data = {})
      api_action(type, id) do |physical_storage|
        raise BadRequestError, 'Validate Physical Storage API must get provider id' unless data.key?('ems_id')

        ems = resource_search(data['ems_id'], :providers)

        raise BadRequestError, "Couldn't find a provider by the provider id - '#{data['ems_id']}'" unless ems

        klass = ems.class_by_ems(physical_storage.name.split(':').last)
        ensure_supports(type, klass, :validate)

        task_id = physical_storage.validate_storage_queue(User.current_userid, ems, data)
        action_result(true, "Validating #{physical_storage.name}", :task_id => task_id)
      end
    end
  end
end
