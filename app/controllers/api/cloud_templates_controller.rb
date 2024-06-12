module Api
  class CloudTemplatesController < BaseController
    def check_compliance_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Check Compliance for", :method_name => "check_compliance", :supports => true)
    end

    def import_resource(_type, _id, data = {})
      required_params = %w[dst_provider_id src_provider_id src_image_id]
      raise BadRequestError, "Parameter 'data' has to contain non-empty values for the keys '#{required_params.join(", ")}', received: '#{data.to_json}'" if data.values_at(*required_params).any?(&:blank?)

      raise BadRequestError, "Source and destination provider identifiers must differ" if data['dst_provider_id'] == data['src_provider_id']

      ems_dst   = resource_search(data['dst_provider_id'], :providers)
      ems_src   = resource_search(data['src_provider_id'], :providers)

      if ems_src.kind_of?(ManageIQ::Providers::CloudManager)
        src_image = resource_search(data['src_image_id'], :templates)
        optional_params = %w[obj_storage_id cos_container_id cloud_volume_type_id]
        if data.values_at(*optional_params).any?
          raise BadRequestError, "Either provide all of the Object-Storage related parameters (well-formed) or none" if data.values_at(*optional_params).any?(&:blank?)

          cos = resource_search(data['obj_storage_id'], :providers)
          cos_container = resource_search(data['cos_container_id'], :cloud_object_store_containers)
          resource_search(data['cloud_volume_type_id'], :cloud_volume_types)

          raise BadRequestError, "Cloud object store container specified by the id '#{data['cos_container_id']}' does not belong to the object store provider with id '#{data['obj_storage_id']}'" if cos_container.ems_id != cos.id
          raise BadRequestError, "Source image (template) specified by the id '#{data['src_image_id']}' does not belong to the source provider with id '#{ems_src.id}'" if src_image.ems_id != ems_src.id
        end
      elsif ems_src.kind_of?(ManageIQ::Providers::StorageManager) && ems_src.supports?(:object_storage)
        required_params = %w[cos_container_id cloud_volume_type_id]
        raise BadRequestError, "Parameter 'data' has to contain non-empty values for the keys '#{required_params.join(", ")}', received: '#{data.to_json}'" if data.values_at(*required_params).any?(&:blank?)

        src_image = resource_search(data['src_image_id'], :cloud_object_store_objects)
        cos_container = resource_search(data['cos_container_id'], :cloud_object_store_containers)
        resource_search(data['cloud_volume_type_id'], :cloud_volume_types)

        raise BadRequestError, "Cloud object store container specified by the id '#{data['cos_container_id']}' does not belong to the object store provider with id '#{data['src_provider_id']}'" if cos_container.ems_id != ems_src.id
      else
        raise BadRequestError, "Source provider type '#{ems_src.class}' does not support image import"
      end

      task_id = ManageIQ::Providers::CloudManager::Template.import_image_queue(session[:userid], ems_dst, data)
      msg = "Importing image '#{src_image.name}' from '#{ems_src.name}' into '#{ems_dst.name}'."
      api_log_info(msg)

      action_result(true, msg, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end
  end
end
