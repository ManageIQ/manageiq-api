module Api
  class DataStoresController < BaseController
    include Subcollections::Tags

    def delete_resource_main_action(type, data_store, _data)
      {:task_id => queue_object_action(data_store, "Deleting #{model_ident(data_store, type)}", :method_name => "destroy")}
    end
  end
end
