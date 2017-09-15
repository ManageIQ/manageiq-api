module Api
  class GenericObjectDefinitionsController < BaseController
    def create_resource(_type, _id, data)
      klass = collection_class(:generic_object_definitions)
      klass.create!(data.deep_symbolize_keys)
    rescue => err
      raise BadRequestError, "Failed to create new generic object definition - #{err}"
    end

    def edit_resource(type, id, data)
      go_def = fetch_generic_object_definition(type, id, data)
      updated_data = data['resource'].try(:deep_symbolize_keys) || data.deep_symbolize_keys
      go_def.update_attributes!(updated_data) if data.present?
      go_def
    rescue => err
      raise BadRequestError, "Failed to update generic object definition - #{err}"
    end

    def delete_resource(type, id, data = {})
      go_def = fetch_generic_object_definition(type, id, data)
      go_def.destroy!
    rescue => err
      raise BadRequestError, "Failed to delete generic object definition - #{err}"
    end

    def add_attributes_resource(type, id, data)
      go_def = fetch_generic_object_definition(type, id, data)
      attributes = data['attributes'] || data['resource']['attributes']
      attributes.each do |name, attribute_type|
        go_def.add_property_attribute(name, attribute_type)
      end
      go_def
    rescue => err
      raise BadRequestError, "Failed to add attributes to generic object definition - #{err}"
    end

    def remove_attributes_resource(type, id, data)
      go_def = fetch_generic_object_definition(type, id, data)
      attributes = data['attributes'] || data['resource']['attributes']
      attributes.each do |name, _type|
        go_def.delete_property_attribute(name)
      end
      go_def
    rescue => err
      raise BadRequestError, "Failed to remove attributes from generic object definition - #{err}"
    end

    def add_associations_resource(type, id, data)
      go_def = fetch_generic_object_definition(type, id, data)
      associations = data['associations'] || data['resource']['associations']
      associations.each do |name, association_type|
        go_def.add_property_association(name, association_type)
      end
      go_def
    rescue => err
      raise BadRequestError, "Failed to add attributes to object definition - #{err}"
    end

    def remove_associations_resource(type, id, data)
      go_def = fetch_generic_object_definition(type, id, data)
      associations = data['associations'] || data['resource']['associations']
      associations.each do |name, _type|
        go_def.delete_property_association(name)
      end
      go_def
    rescue => err
      raise BadRequestError, "Failed to add attributes to object definition - #{err}"
    end

    def add_methods_resource(type, id, data)
      go_def = fetch_generic_object_definition(type, id, data)
      methods = data['methods'] || data['resource']['methods']
      methods.each do |name|
        go_def.add_property_method(name)
      end
      go_def
    rescue => err
      raise BadRequestError, "Failed to add attributes to object definition - #{err}"
    end

    def remove_methods_resource(type, id, data)
      go_def = fetch_generic_object_definition(type, id, data)
      methods = data['methods'] || data['resource']['methods']
      methods.each do |name|
        go_def.delete_property_method(name)
      end
      go_def
    rescue => err
      raise BadRequestError, "Failed to add attributes to object definition - #{err}"
    end

    def self.allowed_association_types
      GenericObjectDefinition::ALLOWED_ASSOCIATION_TYPES.collect do |association_type|
        [Dictionary.gettext(association_type, :type => :model, :notfound => :titleize, :plural => false), association_type]
      end.sort
    end

    def self.allowed_types
      GenericObjectDefinition::TYPE_MAP.keys.collect do |type|
        [Dictionary.gettext(type.to_s, :type => :data_type, :notfound => :titleize, :plural => false), type.to_s]
      end.sort
    end

    def options
      render_options(:generic_object_definitions, build_generic_object_definition_options)
    end

    def build_generic_object_definition_options
      {
        :allowed_association_types => GenericObjectDefinitionsController.allowed_association_types,
        :allowed_types             => GenericObjectDefinitionsController.allowed_types
      }
    end

    private

    def fetch_generic_object_definition(type, id, data)
      id ||= data['name']
      resource_search(id, type, collection_class(type))
    end

    def resource_search(id, type, klass)
      if ApplicationRecord.compressed_id?(id)
        super
      else
        go_def = klass.find_by!(:name => id)
        filter_resource(go_def, type, klass)
      end
    end
  end
end
