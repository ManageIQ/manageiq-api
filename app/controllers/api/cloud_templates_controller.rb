module Api
  class CloudTemplatesController < BaseController
    def check_compliance_resource(type, id, _data = nil)
      api_action(type, id) do |klass|
        cloud_template = resource_search(id, type, klass)
        api_log_info("Checking compliance of #{cloud_template_ident(cloud_template)}")
        request_compliance_check(cloud_template)
      end
    end

    def import_resource(_type, _id, data = {})
      params = %w[dst_provider_id src_provider_id src_image_id]
      raise BadRequestError, "Parameter 'data' has to contain non-empty values for the keys '#{params.join(", ")}', received: '#{data.to_json}'" if data.values_at(*params).any?(&:blank?)
      raise BadRequestError, "Source and destination provider identifiers must differ" if data['dst_provider_id'] == data['src_provider_id']

      ems_dst   = resource_search(data['dst_provider_id'], :providers, collection_class(:providers))
      ems_src   = resource_search(data['src_provider_id'], :providers, collection_class(:providers))
      src_image = resource_search(data['src_image_id'],    :providers, collection_class(:templates))

      raise BadRequestError, "Source image specified by the id '#{data['src_image_id']}' does not belong to the source provider with id '#{ems_src.id}'" if src_image.ems_id != ems_src.id

      task_id = ManageIQ::Providers::CloudManager::Template.import_image_queue(session[:userid], ems_dst, data)
      msg = "Importing image '#{src_image.name}' from '#{ems_src.name}' into '#{ems_dst.name}'."
      api_log_info(msg)

      action_result(true, msg, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    private

    def cloud_template_ident(cloud_template)
      "CloudTemplate id:#{cloud_template.id} name:'#{cloud_template.name}'"
    end

    def request_compliance_check(cloud_template)
      desc = "#{cloud_template_ident(cloud_template)} check compliance requested"
      raise "#{cloud_template_ident(cloud_template)} has no compliance policies assigned" unless cloud_template.has_compliance_policies?

      task_id = queue_object_action(cloud_template, desc, :method_name => "check_compliance")
      action_result(true, desc, :task_id => task_id)
    rescue StandardError => err
      action_result(false, err.to_s)
    end
  end
end
