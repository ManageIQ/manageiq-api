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
      raise BadRequestError, "Must specify a button_id" unless data["button_id"]

      custom_button_set = resource_search(id, type)
      custom_button_set.add_button(data["button_id"])
      action_result(true, "Button assigned to group")
    rescue StandardError => err
      action_result(false, "Could not add custom button to group - #{err}")
    end
  end
end
