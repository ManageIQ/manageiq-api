module Api
  class ContainerImagesController < BaseController
    include Subcollections::CustomAttributes

    def scan_resource(type, id, _payload)
      api_resource(type, id, "Scanning") do |image|
        if (task = image.scan)
          {:task_id => task.id}
        else
          action_result(false, "Failed Scanning #{model_ident(image, type)}")
        end
      end
    end

    def check_compliance_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Check Compliance for", :method_name => "check_compliance", :supports => true)
    end
  end
end
