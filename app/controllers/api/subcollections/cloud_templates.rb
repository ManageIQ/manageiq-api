module Api
  module Subcollections
    module CloudTemplates
      def cloud_templates_query_resource(object)
        object.vms_and_templates.where(:template => true)
      end
    end
  end
end
