module Api
  class PictureSerializer < BaseSerializer
    def self.additional_attributes
      @additional_attributes ||= %w(extension image_href).freeze
    end
  end
end
