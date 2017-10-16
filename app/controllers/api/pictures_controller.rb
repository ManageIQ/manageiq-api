module Api
  class PicturesController < BaseController
    before_action :set_additional_attributes, :only => [:index, :show]

    def create_resource(_type, _id, data)
      Picture.create_from_base64(data)
    rescue => err
      raise BadRequestError, "Failed to create Picture - #{err}"
    end

    private

    def set_additional_attributes
      @additional_attributes = %w(image_href extension)
    end
  end
end
