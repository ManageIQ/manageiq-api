module Api
  class CustomButtonsController < BaseController
    def create_resource(_type, _id, data)
      CustomButton.transaction do
        CustomButton.new(data.except("resource_action", "options")).tap do |cb|
          cb.userid = User.current_user.userid
          cb.options = data["options"].deep_symbolize_keys if data["options"]
          cb.create_resource_action!(data["resource_action"].deep_symbolize_keys) if data.key?("resource_action")
          cb.save!
        end
      end
    rescue => err
      raise BadRequestError, "Failed to create new custom button - #{err.message}"
    end

    def edit_resource(type, id, data)
      return if data.empty?

      CustomButton.transaction do
        fetch_custom_button(type, id).tap do |cb|
          updated_data = (data['resource'] || data).dup
          if (resource_action = updated_data.delete("resource_action")).present?
            cb.resource_action = create_or_update_resource_action(resource_action)
          end
          cb.update!(updated_data.deep_symbolize_keys)
        end
      end
    rescue => err
      raise BadRequestError, "Failed to update custom button - #{err.message}"
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
      id = data.delete("id")
      if id.present?
        ResourceAction.find(id).tap { |ra| ra.attributes = data }
      else
        ResourceAction.new(data)
      end
    end

    def fetch_custom_button(type, id)
      resource_search(id, type, collection_class(type))
    end
  end
end
