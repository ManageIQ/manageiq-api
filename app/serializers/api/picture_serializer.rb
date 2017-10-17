module Api
  class PictureSerializer < BaseSerializer
    ADDITIONAL_ATTRIBUTES = %w[extension image_href].freeze
  end
end
