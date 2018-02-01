module Api
  class ContainerImagesController < BaseController
    def openscap_scan_results_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for getting OpenScap results of a #{type} resource" unless id
      api_action(type, id) do |klass|
        cimage = resource_search(id, type, klass)
        summary = cimage.openscap_rule_results
        action_result(true, "summary" => summary)
      end
    end

    def scan_resource(type, image_id, _payload)
      raise BadRequestError, "Must specify an id for scanning a #{type} resource" unless image_id
      api_action(type, image_id) do |klass|
        image = resource_search(image_id, type, klass)
        begin
          task = image.scan
          if task.present?
            action_result(true, "#{container_image_ident(image)} scanning", :task_id => task.id)
          else
            action_result(false, "#{container_image_ident(image)} failed to start scanning")
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
