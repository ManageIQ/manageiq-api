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
  end
end
