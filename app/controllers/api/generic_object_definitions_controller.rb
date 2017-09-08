module Api
  class GenericObjectDefinitionsController < BaseController
    def create_resource(_type, _id, data)
      klass = collection_class(:generic_object_definitions)
      klass.create!(data.deep_symbolize_keys)
    rescue => err
      raise BadRequestError, "Failed to create new generic object definition - #{err}"
    end

    def edit_resource(type, id, data)
      id ||= data['name']
      go_def = resource_search(id, type, collection_class(:generic_object_definitions))
      updated_data = data['resource'].try(:deep_symbolize_keys) || data.deep_symbolize_keys
      go_def.update_attributes!(updated_data) if data.present?
      go_def
    rescue => err
      raise BadRequestError, "Failed to update generic object definition - #{err}"
    end

    def delete_resource(type, id, data = {})
      id ||= data['name']
      go_def = resource_search(id, type, collection_class(:generic_object_definitions))
      go_def.destroy!
    rescue => err
      raise BadRequestError, "Failed to delete generic object definition - #{err}"
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
