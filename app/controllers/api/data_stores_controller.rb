module Api
  class DataStoresController < BaseController
    include Subcollections::Tags

    def delete_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Deleting", :method_name => "destroy")
    end
  end
end
