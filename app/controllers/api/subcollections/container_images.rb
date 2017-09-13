# frozen_string_literal: true

module Api
  module Subcollections
    module ContainerImages
      def container_images_scan_resource(provider_id, type, image_id, _payload)
        api_action(type, image_id, :skip_href => true) do |klass|
          image = resource_search(image_id, type, klass)
          begin
            task_id = image.scan
            if task_id.present?
              desc = "#{container_image_ident(image)} scanning"
              action_result(true, desc).merge(:task_id => task_id, :parent_id => provider_id)
            else
              desc = "#{container_image_ident(image)} failed to start scanning"
              action_result(false, desc).merge(:task_id => task_id, :parent_id => provider_id)
            end
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
