module Api
  class ConfigurationScriptPayloadsController < BaseController
    include Subcollections::Authentications

    def api_resource_action_options
      # ConfigurationScriptPayloads do not have any passwords stored directly
      # in the record, they reference the Authentication model via the
      # credentials jsonb mapping.  The names of these mappings are user defined
      # and can include e.g. "api_password" => {"credential_ref" => ..} and this
      # entire key would be removed from the payload.
      #
      # Since there aren't any encrypted attributes in this record it is safe
      # to include encrypted attributes in the payload response.
      %w[include_encrypted_attributes]
    end

    def edit_resource(type, id, data)
      resource = resource_search(id, type)

      allowed_params  = %w[description credentials]
      allowed_params += %w[name payload payload_type] if resource.configuration_script_source.nil?

      unpermitted_params = data.keys.map(&:to_s) - allowed_params
      raise BadRequestError, _("Invalid parameters: %{params}" % {:params => unpermitted_params.join(", ")}) if unpermitted_params.any?

      # If a credentials payload is provided, map any requested authentication
      # records to the configuration_script_payload via the
      # authentications_configuration_script_payloads join table.
      unless data["credentials"].nil?
        # Credentials can be a static string or a payload with an external
        # Authentication record referenced by credential_ref and credential_field.
        credential_refs = data["credentials"].values.select { |val| val.kind_of?(Hash) }.pluck("credential_ref")
        # Lookup the Authentication record by ems_ref in the parent manager's
        # list of authentications.
        credentials     = resource.manager&.authentications&.where(:ems_ref => credential_refs) || []
        # Filter the collection based on the current user's RBAC roles.
        credentials, _  = collection_filterer(credentials, "authentications", ::Authentication)
        # If any requested authentications were unable to be found, either due
        # to a bad credential_ref or due to RBAC then raise a 400 BadRequestError.
        missing_credential_refs = credential_refs - credentials.pluck(:ems_ref)
        if missing_credential_refs.any?
          raise BadRequestError,
                _("Could not find credentials %{missing_credential_refs}") %
                {:missing_credential_refs => missing_credential_refs}
        end
        # Reset the authentications collection with the current set of credentials.
        # This will also remove any credential references not in the new payload.
        resource.authentications = credentials
      end

      resource.update!(data.except(*ID_ATTRS))
      resource
    end
  end
end
