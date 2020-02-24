module Api
  class CustomButtonsController < BaseController
    def create_resource(_type, _id, data)
      CustomButton.transaction do
        custom_button = CustomButton.new(data.except("resource_action", "options"))
        custom_button.userid = User.current_user.userid
        custom_button.options = data["options"].deep_symbolize_keys if data["options"]
        custom_button.resource_action.update!(data["resource_action"].deep_symbolize_keys) if data.key?("resource_action")
        custom_button.save!
        custom_button
      end
    rescue
      raise BadRequestError, "Failed to create new custom button - #{custom_button.errors.full_messages.join(", ")}"
    end

    def edit_resource(type, id, data)
      return if data.empty?

      CustomButton.transaction do
        custom_button = fetch_custom_button(type, id)
        updated_data = data['resource'] || data
        if updated_data['resource_action'].present?
          custom_button.resource_action = create_or_update_resource_action(updated_data['resource_action'])
        end
        updated_data.except!('resource_action')
        custom_button.update!(updated_data.deep_symbolize_keys) if updated_data.present?
        custom_button
      end
    rescue => err
      raise BadRequestError, "Failed to update custom button - #{err}"
    end

    def options
      render_options(:custom_buttons, build_custom_button_options)
    end

    def build_custom_button_options
      {
        :custom_button_types => CustomButton::TYPES
      }
    end

    private

    def create_or_update_resource_action(data)
      return nil if data.empty?
      id = data["id"]
      if id.present?
        resource_action = ResourceAction.find(id)
        data.except!("id")
        resource_action.update!(data.deep_symbolize_keys)
        resource_action
      else
        ResourceAction.create(data)
      end
    end

    def fetch_custom_button(type, id)
      resource_search(id, type, collection_class(type))
    end
  end
end
