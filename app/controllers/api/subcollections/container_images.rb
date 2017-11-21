# frozen_string_literal: true

module Api
  module Subcollections
    module ContainerImages
      def container_images_scan_resource(provider_id, type, image_id, _payload)
        api_action(type, image_id, :skip_href => true) do |klass|
          image = resource_search(image_id, type, klass)
          begin
            desc = "#{container_image_ident(image)} scanning"
            task_id = image.scan
            url = api_provider_container_image_url(nil, provider_id, image_id)
            action_result(true, desc).merge(:task_id => task_id, :href => url)
          rescue => err
            action_result(false, err.to_s)
          end
        end
      end

      private

      def container_image_ident(image)
        "ContainerImage id:#{image.id} name:'#{image.name}'"
      end
    end
  end
end
