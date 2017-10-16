module Api
  class PictureSerializer < BaseSerializer
    def additional_attributes
      %w(extension image_href)
    end
  end
end
