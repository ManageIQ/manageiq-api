module Api
  class GenericObjectsController < BaseController
    EXCEPTION_ATTRS = %w(generic_object_definition associations).freeze

    before_action :set_additional_attributes, :only => [:index, :show]

    def create_resource(_type, _id, data)
      object_def = retrieve_generic_object_definition(data)
      generic_object = object_def.create_object(data.except(*EXCEPTION_ATTRS))
      add_associations(generic_object, data)
    rescue => err
      raise BadRequestError, "Failed to create new generic object - #{err}"
    end

    private

    def set_additional_attributes
      @additional_attributes = %w(property_attributes)
    end

    def retrieve_generic_object_definition(data)
      definition_id = parse_id(data['generic_object_definition'], :generic_object_definitions)
      resource_search(definition_id, :generic_object_definitions, collection_class(:generic_object_definitions))
    end

    def add_associations(generic_object, data)
      data['associations'].each do |association, resource_refs|
        resources = resource_refs.collect do |ref|
          collection, id = parse_href(ref['href'])
          resource_search(id, collection, collection_class(collection))
        end
        generic_object.add_to_property_association(association, resources)
      end
      generic_object
    end
  end
end
