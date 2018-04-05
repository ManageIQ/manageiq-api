module Api
  class AutomateWorkspacesController < BaseController
    def edit_resource(type, id, data = {})
      raise BadRequestError, "must contain at least one attribute to edit" if data.blank?
      obj = resource_search(id, type, collection_class(type))
      obj.merge_output!(data)
    end

    def decrypt_resource(type, id = nil, data = nil)
      obj = resource_search(id, type, collection_class(type))
      decrypt(obj, data)
    end

    def encrypt_resource(type, id = nil, data = nil)
      obj = resource_search(id, type, collection_class(type))
      obj.encrypt(data['object'], data['attribute'], data['value'])
    end

    private

    def decrypt(obj, data)
      {'object'    => data['object'],
       'attribute' => data['attribute'],
       'value'     => obj.decrypt(data['object'], data['attribute'])}
    end

    def normalize_attr(attr, value, type = nil)
      return "password::********" if value.kind_of?(String) && value.start_with?("password::")
      super
    end
  end
end
