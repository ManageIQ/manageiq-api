module Api
  class CustomButtonSetsController < BaseController
    def create_resource(type, id, data)
      super(type, id, data.deep_symbolize_keys)
    end

    def edit_resource(type, id, data)
      super(type, id, data.deep_symbolize_keys)
    end
  end
end
