module Api
  class CustomButtonSetsController < BaseController
    def create_resource(type, id, data)
      super(type, id, data.deep_symbolize_keys)
    end

    def edit_resource(type, id, data)
      super(type, id, data.deep_symbolize_keys)
    end

    def options
      render_options(:custom_button_sets, build_custom_button_sets_options)
    end

    def build_custom_button_sets_options
      {
        :custom_button_sets => {
          :generic_object_definitions => CustomButtonSet.find_all_by_class_name('GenericObjectDefinition'),
          :service_templates          => CustomButtonSet.find_all_by_class_name('ServiceTemplate')
        }
      }
    end
  end
end
