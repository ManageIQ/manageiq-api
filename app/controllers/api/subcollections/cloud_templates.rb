module Api
  module Subcollections
    module CloudTemplates
      def cloud_templates_query_resource(object)
        object.vms_and_templates.where(:template => true)
      end

      def cloud_templates_create_resource(parent, _type, _id, data)
        task_id = ManageIQ::Providers::CloudManager::Template.create_image_queue(User.current_userid, parent, data)
        action_result(true, 'Creating Image', :task_id => task_id)
      rescue => err
        action_result(false, err.to_s)
      end

      def cloud_templates_edit_resource(_object, type, id = nil, data = {})
        raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id
        image = resource_search(id, type, collection_class(:cloud_templates))

        task_id = image.update_image_queue(User.current_userid, data)
        action_result(true, "Updating #{image_ident(image)}", :task_id => task_id)
      rescue => err
        action_result(false, err.to_s)
      end

      def cloud_templates_delete_resource(_parent, type, id, _data)
        image = resource_search(id, type, collection_class(type))
        task_id = image.delete_image_queue(User.current_userid)
        action_result(true, "Deleting #{image_ident(image)}", :task_id => task_id)
      rescue => err
        action_result(false, err.to_s)
      end
      alias delete_resource_cloud_templates cloud_templates_delete_resource

      private

      def image_ident(image)
        "Image id:#{image.id} name: '#{image.name}'"
      end
    end
  end
end
