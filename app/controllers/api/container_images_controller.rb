module Api
  class ContainerImagesController < BaseController
    include Subcollections::CustomAttributes

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

    def check_compliance_resource(type, id, _data = nil)
      api_action(type, id) do |klass|
        container_image = resource_search(id, type, klass)
        api_log_info("Checking compliance of #{container_image_ident(container_image)}")
        request_compliance_check(container_image)
      end
    end

    private

    def container_image_ident(image)
      "ContainerImage id:#{image.id} name:'#{image.name}'"
    end

    def request_compliance_check(container_image)
      desc = "#{container_image_ident(container_image)} check compliance requested"
      raise "#{container_image_ident(container_image)} has no compliance policies assigned" if container_image.compliance_policies.blank?

      task_id = queue_object_action(container_image, desc, :method_name => "check_compliance")
      action_result(true, desc, :task_id => task_id)
    rescue StandardError => err
      action_result(false, err.to_s)
    end
  end
end
