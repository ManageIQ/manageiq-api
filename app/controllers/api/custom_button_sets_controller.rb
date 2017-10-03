module Api
  class CustomButtonSetsController < BaseController
    def create_resource(_type, _id, data)
      klass = collection_class(:custom_button_sets)
      klass.create!(data.deep_symbolize_keys)
    rescue => err
      raise BadRequestError, "Failed to create new custom button - #{err}"
    end

    def edit_resource(type, id, data)
      custom_button_set = fetch_custom_button_set(type, id, data)
      updated_data = data['resource'].try(:deep_symbolize_keys) || data.deep_symbolize_keys
      custom_button_set.update_attributes!(updated_data) if data.present?
      custom_button_set
    rescue => err
      raise BadRequestError, "Failed to update custom button set - #{err}"
    end

    def delete_resource(type, id, data = {})
      custom_button_set = fetch_custom_button_set(type, id, data)
      custom_button_set.destroy!
    rescue => err
      raise BadRequestError, "Failed to delete custom button set - #{err}"
    end

    private

    def fetch_custom_button_set(type, id, _data)
      resource_search(id, type, collection_class(type))
    end

    def resource_search(id, type, klass)
      if ApplicationRecord.compressed_id?(id)
        super
      else
        custom_button_set = klass.find_by!(:id => id)
        filter_resource(custom_button_set, type, klass)
      end
    end
  end
end
