module Api
  class CategoriesController < BaseController
    include Subcollections::Tags

    before_action :set_additional_attributes, :only => [:index, :show, :update]

    def edit_resource(type, id, data = {})
      raise ForbiddenError if Category.find(id).read_only?
      super
    end

    def delete_resource_main_action(type, category, _data)
      raise ForbiddenError if category.read_only?

      super
    end

    private

    def set_additional_attributes
      @additional_attributes = %w(name)
    end
  end
end
