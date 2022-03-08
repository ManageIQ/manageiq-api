module Api
  class CloudTemplatesController < BaseController
    def check_compliance_resource(type, id, _data = nil)
      enqueue_ems_action(type, id, "Check Compliance for", :method_name => "check_compliance", :supports => true)
    end

    def import_resource(_type, _id, data = {})
      params = %w[dst_provider_id src_provider_id src_image_id]
      raise BadRequestError, "Parameter 'data' has to contain non-empty values for the keys '#{params.join(", ")}', received: '#{data.to_json}'" if data.values_at(*params).any?(&:blank?)
      raise BadRequestError, "Source and destination provider identifiers must differ" if data['dst_provider_id'] == data['src_provider_id']

      ems_dst   = resource_search(data['dst_provider_id'], :providers)
      ems_src   = resource_search(data['src_provider_id'], :providers)
      src_image = resource_search(data['src_image_id'], :templates)

      opt_params = %w[obj_storage_id bucket_id disk_type_id]
      if data.values_at(*opt_params).any?
        raise BadRequestError, "Either provide all of the Object-Storage related parameters (well-formed) or none" if data.values_at(*opt_params).any?(&:blank?)

        cos = resource_search(data['obj_storage_id'], :providers)
        bucket = resource_search(data['bucket_id'], :cloud_object_store_containers)
        resource_search(data['disk_type_id'], :cloud_volume_types)

        raise BadRequestError, "Object bucket specified by the id '#{data['bucket_id']}' does not belong to the object storage provider with id '#{data['obj_storage_id']}'" if bucket.ems_id != cos.id
      end

      raise BadRequestError, "Source image specified by the id '#{data['src_image_id']}' does not belong to the source provider with id '#{ems_src.id}'" if src_image.ems_id != ems_src.id

      task_id = ManageIQ::Providers::CloudManager::Template.import_image_queue(session[:userid], ems_dst, data)
      msg = "Importing image '#{src_image.name}' from '#{ems_src.name}' into '#{ems_dst.name}'."
      api_log_info(msg)

      action_result(true, msg, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end
  end
end
