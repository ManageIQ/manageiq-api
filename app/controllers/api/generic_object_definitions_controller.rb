module Api
  class GenericObjectDefinitionsController < BaseController
    def show
      object = fetch_generic_object_definition(@req.c_id)
      render_resource(:generic_object_definitions, object)
    end

    def create_resource(_type, _id, data)
      klass = collection_class(:generic_object_definitions)
      klass.create!(data.deep_symbolize_keys)
    rescue => err
      raise BadRequestError, "Failed to create new generic object definition - #{err}"
    end

    def edit_resource(_type, id, data)
      id ||= data['name']
      go_def = fetch_generic_object_definition(id)
      updated_data = data['resource'].try(:deep_symbolize_keys) || data.deep_symbolize_keys
      go_def.update_attributes!(updated_data) if data.present?
      go_def
    rescue => err
      raise BadRequestError, "Failed to update generic object definition - #{err}"
    end

    def delete_resource(_type, id, data = {})
      id ||= data['name']
      go_def = fetch_generic_object_definition(id)
      go_def.destroy!
    rescue => err
      raise BadRequestError, "Failed to delete generic object definition - #{err}"
    end

    private

    def fetch_generic_object_definition(id)
      klass = collection_class(:generic_object_definitions)
      go_def = klass.find_by(:name => id) || klass.find(id)
      go_def = Rbac.filtered_object(go_def, :user => User.current_user, :class => klass)
      raise ForbiddenError, "Access to Generic Object Definition id: #{id} is forbidden" unless go_def
      go_def
    end
  end
end
