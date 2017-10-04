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
        generic_object.update_attributes!(data.except(*ADDITIONAL_ATTRS))
        add_associations(generic_object, data, generic_object.generic_object_definition) if data.key?('associations')
        generic_object.save!
      end
    rescue => err
      raise BadRequestError, "Failed to update generic object - #{err}"
    end

    private

    def retrieve_generic_object_definition(data)
      definition_id = parse_id(data['generic_object_definition'], :generic_object_definitions)
      resource_search(definition_id, :generic_object_definitions, collection_class(:generic_object_definitions))
    end
  end
end
