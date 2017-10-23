module Api
  class CustomButtonsController < BaseController
    def create_resource(_type, _id, data)
      custom_button = CustomButton.new(data.except("resource_action"))
      custom_button.userid = User.current_user.userid
      custom_button.resource_action = find_or_create_resource_action(data["resource_action"]) if data.key?("resource_action")
      custom_button.save!
    rescue => err
      raise BadRequestError, "Failed to create new custom button - #{err}"
    end

    def edit_resource(type, id, data)
      custom_button = fetch_custom_button(type, id)
      updated_data = data['resource'] || data
      updated_data['resource_action'] = find_or_create_resource_action(updated_data['resource_action']) if updated_data.key?('resource_action')
      custom_button.update_attributes!(updated_data.deep_symbolize_keys) if data.present?
      custom_button
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

    def find_or_create_resource_action(data)
      return nil if data.empty?
      id = parse_id(data, :resource_actions)
      return resource_search(id, :resource_actions, collection_class(:resource_actions)) if id
      ResourceAction.create(data)
    end

    def fetch_custom_button(type, id)
      resource_search(id, type, collection_class(type))
    end
  end
end
