module Api
  class FirmwareRegistriesController < BaseController
    def create_resource(type, _id, data)
      assert_id_not_specified(data, type)
      collection_class(type).create_firmware_registry(data.symbolize_keys)
    end

    def sync_fw_binaries_resource(type, id, _data)
      resource_search(id, type, collection_class(type)).sync_fw_binaries_queue
      action_result(true, "FirmwareBinary [id: #{id}] synced")
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource(type, id, _data = {})
      delete_action_handler do
        resource_search(id, type, collection_class(:firmware_registries)).destroy
        action_result(true, "FirmwareBinary [id: #{id}] deleted")
      end
    end
  end
end
