module Api
  class PicturesController < BaseController
    include Api::Mixins::Pictures

    before_action :set_additional_attributes, :only => [:index, :show]

    def create_resource(_type, _id, data)
      picture = Picture.create_from_base64(data)
      format_picture_response(picture)
    rescue => err
      raise BadRequestError, "Failed to create Picture - #{err}"
    end

    private

    def set_additional_attributes
      @additional_attributes = %w(image_href extension)
    end

    def attribute_selection
      if !@req.attributes.empty? || @additional_attributes
        @req.attributes | Array(@additional_attributes) | ID_ATTRS
      else
        Picture.attribute_names | Picture.try(:attribute_aliases)&.keys - %w(content)
      end
    end
  end
end
