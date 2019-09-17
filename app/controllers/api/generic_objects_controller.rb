module Api
  class GenericObjectsController < BaseController
    include Api::Mixins::GenericObjects
    include Subcollections::Tags

    ADDITIONAL_ATTRS = %w(generic_object_definition associations).freeze

    before_action :set_additional_attributes
    before_action :set_associations, :only => [:index, :show]

    def create_resource(_type, _id, data)
      object_def = retrieve_generic_object_definition(data)
      create_generic_object(object_def, data)
    rescue => err
      raise BadRequestError, "Failed to create new generic object - #{err}"
    end

    def edit_resource(type, id, data)
      resource_search(id, type, collection_class(type)).tap do |generic_object|
        generic_object.update!(data.except(*ADDITIONAL_ATTRS))
        add_associations(generic_object, data, generic_object.generic_object_definition) if data.key?('associations')
        generic_object.save!
      end
    rescue => err
      raise BadRequestError, "Failed to update generic object - #{err}"
    end

    private

    def invoke_custom_action(type, resource, action, data)
      return super(type, resource.reload, action, data) if resource_custom_action_button(resource, action)
      result = begin
                 description = method_description(resource, action)
                 task_id = queue_object_action(resource, description, queue_args(action, data))
                 action_result(true, description, :task_id => task_id)
               rescue => err
                 action_result(false, err.to_s)
               end
      add_href_to_result(result, type, resource.id)
      log_result(result)
      result
    end
    def method_description(resource, action)
      "Invoked method #{resource.generic_object_definition.name}##{action} for Generic Object id: #{resource.id} name: #{resource.name}"
    end

    def retrieve_generic_object_definition(data)
      definition_id = parse_id(data['generic_object_definition'], :generic_object_definitions)
      resource_search(definition_id, :generic_object_definitions, collection_class(:generic_object_definitions))
    end

    def queue_args(action, data)
      current_user = User.current_user
      {
        :method_name => action,
        :args        => data['parameters'],
        :role        => 'automate',
        :user        => {
          :user_id   => current_user.id,
          :group_id  => current_user.current_group.id,
          :tenant_id => current_user.current_tenant.id
        }
      }
    end
  end
end
