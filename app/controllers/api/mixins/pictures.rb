module Api
  module Mixins
    module Pictures
      def fetch_picture(resource)
        format_picture_response(resource.picture)
      end

      def format_picture_response(picture)
        return unless picture
        picture_hash = picture.attributes.except('content').merge('image_href' => picture.image_href,
                                                                  'href'       => picture.href_slug)
        normalize_hash(:picture, picture_hash)
      end
    end
  end
end
