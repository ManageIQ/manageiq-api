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
      src_image = resource_search(data['src_image_id'], :providers, collection_class(:templates))
      resource_search(data['obj_storage_id'], :providers) if data['obj_storage_id'].present?
      resource_search(data['bucket_id'], :cloud_object_store_containers) if data['bucket_id'].present?
      resource_search(data['bucket_id'], :cloud_volume_types) if data['disk_type_id'].present?

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
