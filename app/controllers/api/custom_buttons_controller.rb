module Api
  class CustomButtonsController < BaseController
    def create_resource(_type, _id, data)
      klass = collection_class(:custom_buttons)
      data['resource_action'] = add_resource_action_resource(data['resource_action']) if data.key?('resource_action')
      data['userid'] = User.current_user.userid
      klass.create!(data.deep_symbolize_keys)
    rescue => err
      raise BadRequestError, "Failed to create new custom button - #{err}"
    end

    def edit_resource(type, id, data)
      custom_button = fetch_custom_button(type, id)
      updated_data = data['resource'] || data
      updated_data['resource_action'] = add_resource_action_resource(updated_data['resource_action']) if updated_data.key?('resource_action')
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

    def add_resource_action_resource(data)
      return nil if data.empty?
      id = parse_id(data, :resource_actions)
      return resource_search(id, :resource_actions, collection_class(:resource_actions)) if id
      ResourceAction.create(data)
    end

    def fetch_custom_button(type, id)
      resource_search(id, type, collection_class(type))
    end

    def resource_search(id, type, klass)
      if ApplicationRecord.compressed_id?(id)
        super
      else
        resource_action = klass.find_by!(:name => id)
        filter_resource(resource_action, type, klass)
      end
    end
  end
end
