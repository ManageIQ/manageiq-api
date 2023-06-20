module Api
  class ConfigurationScriptPayloadsController < BaseController
    include Subcollections::Authentications

    def edit_resource(type, id, data)
      resource = resource_search(id, type)

      allowed_params  = %w[description credentials]
      allowed_params += %w[name payload payload_type] if resource.configuration_script_source.nil?

      unpermitted_params = data.keys.map(&:to_s) - allowed_params
      raise BadRequestError, _("Invalid parameters: %{params}" % {:params => unpermitted_params.join(", ")}) if unpermitted_params.any?

      resource.update!(data.except(*ID_ATTRS))
      resource
    end
  end
end
