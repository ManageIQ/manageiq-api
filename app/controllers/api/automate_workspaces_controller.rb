module Api
  class AutomateWorkspacesController < BaseController
    def edit_resource(type, id, data = {})
      raise BadRequestError, "Must specify an id for starting a #{type} resource" unless id

      obj = resource_search(id, type, collection_class(type))
      obj.merge_output!(data)
    end

    def decrypt_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for starting a #{type} resource" unless id

      obj = resource_search(id, type, collection_class(type))
      data['resources'] ? decrypt_all(obj, data) : decrypt_one(obj, data)
    end

    def encrypt_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for starting a #{type} resource" unless id

      obj = resource_search(id, type, collection_class(type))
      obj.encrypt(data['object'], data['attribute'], data['value'])
      obj.reload
      obj
    end

    private

    def decrypt_all(obj, data)
      { "results" => data["resources"].collect { |res| decrypt_one(obj, res) } }
    end

    def decrypt_one(obj, data)
      begin
        value = obj.decrypt(data['object'], data['attribute'])
      rescue
        value = ""
      end
      {'object' => data['object'], 'attribute' => data['attribute'], 'value' => value}
    end
  end
end
