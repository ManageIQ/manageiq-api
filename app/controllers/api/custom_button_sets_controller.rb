module Api
  class CustomButtonSetsController < BaseController
    def create_resource(type, id, data)
      super(type, id, data.deep_symbolize_keys)
    end

    def edit_resource(type, id, data)
      super(type, id, data.deep_symbolize_keys)
    end

    def reorder_resource(type, id, data)
      api_action(type, id) do
        CustomButtonSet.reorder_group_index(data["ids"])
        action_result(true, "Button Group Reorder saved")
      end
    end

    def add_custom_button_resource(type, id, data)
      api_action(type, id) do
        raise BadRequestError, "Must specify a button_id" unless data["button_id"]

        resource_search(id, type).add_button(data["button_id"])
        action_result(true, "Button assigned to group")
      end
    end
  end
end
