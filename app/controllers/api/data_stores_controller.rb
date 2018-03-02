module Api
  class DataStoresController < BaseController
    include Subcollections::Tags

    def delete_resource(type, id = nil, _data = nil)
      delete_action_handler do
        data_store = resource_search(id, type, collection_class(type))
        desc = "Deleting #{data_store_ident(data_store)}"
        api_log_info(desc)
        task_id = queue_object_action(data_store, desc, :method_name => "destroy")
        action_result(true, desc, :task_id => task_id, :parent_id => id)
      end
    end

    private

    def data_store_ident(data_store)
      "Data Store id:#{data_store.id} name:'#{data_store.name}'"
    end
  end
end
