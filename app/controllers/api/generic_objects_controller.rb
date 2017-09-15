module Api
  class GenericObjectsController < BaseController
    ADDITIONAL_ATTRS = %w(generic_object_definition associations).freeze

    before_action :set_additional_attributes
    before_action :set_associations, :only => [:index, :show]

    def create_resource(_type, _id, data)
      object_def = retrieve_generic_object_definition(data)
      object_def.create_object(data.except(*ADDITIONAL_ATTRS)).tap do |generic_object|
        add_associations(generic_object, data)
        generic_object.save!
      end
    rescue => err
      raise BadRequestError, "Failed to create new generic object - #{err}"
    end

    def edit_resource(type, id, data)
      resource_search(id, type, collection_class(type)).tap do |generic_object|
        generic_object.update_attributes!(data.except(*ADDITIONAL_ATTRS))
        add_associations(generic_object, data)
        generic_object.save!
      end
    rescue => err
      raise BadRequestError, "Failed to update generic object - #{err}"
    end

    private

    def set_additional_attributes
      @additional_attributes = %w(property_attributes)
    end

    def set_associations
      return unless params[:associations]
      params[:associations].split(',').each do |prop|
        @additional_attributes << prop
      end
    end

    def retrieve_generic_object_definition(data)
      definition_id = parse_id(data['generic_object_definition'], :generic_object_definitions)
      resource_search(definition_id, :generic_object_definitions, collection_class(:generic_object_definitions))
    end

    def add_associations(generic_object, data)
      return unless data.key?('associations')
      data['associations'].each do |association, resource_refs|
        resources = resource_refs.collect do |ref|
          collection, id = parse_href(ref['href'])
          resource_search(id, collection, collection_class(collection))
        end
        generic_object.send("#{association}=", resources)
      end
    end
  end
end
