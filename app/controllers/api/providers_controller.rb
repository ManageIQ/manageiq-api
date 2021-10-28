module Api
  class ProvidersController < BaseController
    AUTH_TYPE_ATTR    = "auth_type".freeze
    COMMON_DDF_ATTRS  = %w[name zone_id].freeze
    CONNECTION_ATTRS  = %w(connection_configurations).freeze
    CREDENTIALS_ATTR  = "credentials".freeze
    DDF_ATTR          = 'ddf'.freeze
    DEFAULT_AUTH_TYPE = "default".freeze
    ENDPOINT_ATTRS    = %w(verify_ssl hostname url ipaddress port security_protocol certificate_authority).freeze
    TYPE_ATTR         = "type".freeze
    ZONE_ATTR         = "zone".freeze
    RESTRICTED_ATTRS  = [TYPE_ATTR, CREDENTIALS_ATTR, ZONE_ATTR, "zone_id"].freeze

    include Subcollections::Authentications
    include Subcollections::CloudNetworks
    include Subcollections::CloudSubnets
    include Subcollections::CloudTemplates
    include Subcollections::CloudTenants
    include Subcollections::ConfigurationProfiles
    include Subcollections::ConfiguredSystems
    include Subcollections::CustomAttributes
    include Subcollections::Endpoints
    include Subcollections::Flavors
    include Subcollections::Folders
    include Subcollections::Lans
    include Subcollections::LoadBalancers
    include Subcollections::Networks
    include Subcollections::NetworkServices
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::SecurityGroups
    include Subcollections::SecurityPolicies
    include Subcollections::SecurityPolicyRules
    include Subcollections::Tags
    include Subcollections::Vms

    before_action :validate_provider_class

    def create_resource(type, _id, data = {})
      assert_id_not_specified(data, type)

      if data.delete(DDF_ATTR)
        create_provider_ddf(data)
      else
        raise BadRequestError, "Must specify credentials" if data[CREDENTIALS_ATTR].nil? && !data.key?(*CONNECTION_ATTRS)

        create_provider(data)
      end
    end

    def edit_resource(type, id = nil, data = {})
      raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id
      raise BadRequestError, "Provider type cannot be updated" if data.key?(TYPE_ATTR)

      provider = resource_search(id, type, collection_class(:providers))

      if data.delete(DDF_ATTR)
        edit_provider_ddf(provider, data)
      else
        edit_provider(provider, data)
      end
    end

    def refresh_resource(type, id = nil, _data = nil)
      api_resource(type, id, "Refreshing") do |provider|
        {:task_ids => provider.refresh_ems(:create_task => true)}
      end
    end

    def delete_resource_main_action(_type, provider, _data)
      {:task_id => provider.destroy_queue, :parent_id => provider.id}
    end

    def import_vm_resource(type, id = nil, data = {})
      raise BadRequestError, "Must specify an id for import of VM to a #{type} resource" unless id

      api_action(type, id) do |klass|
        provider = resource_search(id, type, klass)

        vm_id = parse_id(data['source'], :vms)
        # check if user can access the VM
        resource_search(vm_id, :vms, Vm)

        api_log_info("Importing VM to #{provider_ident(provider)}")
        target_params = {
          :name       => data.fetch_path('target', 'name'),
          :cluster_id => parse_id(data.fetch_path('target', 'cluster'), :clusters),
          :storage_id => parse_id(data.fetch_path('target', 'data_store'), :data_stores),
          :sparse     => data.fetch_path('target', 'sparse')
        }
        import_vm_to_provider(provider, vm_id, target_params)
      end
    end

    def options
      options = providers_options
      options['provider_form_schema'] = provider_options(params[:type]) if params[:type]
      render_options(:providers, options)
    end

    # Process change_password action for a single resource or a collection of resources
    def change_password_resource(type, id, data = {})
      if single_resource?
        change_password(type, id, data)
      else
        change_password_multiple_providers(type, id, data)
      end
    end

    def verify_credentials_resource(_type, id = nil, data = {})
      klass = fetch_provider_klass(collection_class(:providers), data)
      zone_name = data.delete('zone_name')
      data['id'] = id if id
      task_id = klass.verify_credentials_task(current_user.userid, zone_name, data)
      action_result(true, 'Credentials sent for verification', :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def check_compliance_resource(type, id, _data = nil)
      api_action(type, id) do |klass|
        provider = resource_search(id, type, klass)
        api_log_info("Checking compliance of #{provider_ident(provider)}")
        request_compliance_check(provider)
      end
    end

    private

    def authorize_provider(typed_provider_klass)
      create_action = collection_config["providers"].collection_actions.post.detect { |a| a.name == "create" }
      provider_spec = create_action.identifiers.detect { |i| typed_provider_klass < i.klass.constantize }
      raise BadRequestError, "Unsupported request class #{typed_provider_klass}" if provider_spec.blank?

      if provider_spec.identifier && !api_user_role_allows?(provider_spec.identifier)
        raise ForbiddenError, "Create action is forbidden for #{typed_provider_klass} requests"
      end
    end

    def provider_options(type)
      klass = type.safe_constantize

      raise BadRequestError, "Invalid provider - #{type}" unless klass.try(:<, ExtManagementSystem) && klass.permitted?
      raise BadRequestError, "No DDF specified for - #{type}" unless klass.respond_to?(:params_for_create)

      klass.params_for_create
    end

    def supported_subclasses
      ActiveSupport::Dependencies.interlock.loading do
        ManageIQ::Providers::BaseManager.supported_subclasses
      end
    end

    def supported_types_for_create
      ActiveSupport::Dependencies.interlock.loading do
        ExtManagementSystem.supported_types_for_create
      end
    end

    def providers_options
      providers_options = supported_subclasses.inject({}) do |po, ems|
        po.merge(ems.ems_type => ems.options_description)
      end

      supported_providers = supported_types_for_create.map do |klass|
        if klass.supports?(:regions)
          regions = klass.module_parent::Regions.all.sort_by { |r| r[:description] }.map { |r| r.slice(:name, :description) }
        end

        {
          :title   => klass.description,
          :type    => klass.to_s,
          :kind    => klass.to_s.demodulize.sub(/Manager$/, '').underscore,
          :regions => regions
        }.compact
      end

      { "provider_settings" => providers_options, "supported_providers" => supported_providers }
    end

    # Process password change request for a single resource
    #
    # @raise [BadRequestError] if no id is passed or some required data is missing
    #                          or some error occur when try to change password on provider client
    # @raise [NotFoundError]   if there isn't providers with the id passed
    def change_password(type, id, data)
      raise BadRequestError, "Must specify an id for change password of a #{type} resource" unless id
      api_action(type, id) do |klass|
        provider = resource_search(id, type, klass)
        desc = "Change password requested for Physical Provider #{provider.name}"
        task_id = provider.change_password_queue(User.current_user.userid, data["current_password"], data["new_password"])
        action_result(true, desc, :task_id => task_id)
      end
    end

    # Process password change for a collection of resources
    #
    # Even the request isn't completed successfully, return a HTTP Status 200
    #   with individual response for all resources.
    #
    # @see #change_password
    #
    # @return [Hash] contains details about the request proccess
    #   :success [Boolean] indicates if the request was successfully completed
    #   :message [String]  description of request proccess
    def change_password_multiple_providers(type, id, data)
      change_password(type, id, data)
    rescue BadRequestError, ActiveRecord::RecordNotFound, MiqException::Error => exception
      action_result(false, _(exception.message))
    end

    def provider_ident(provider)
      "Provider id:#{provider.id} name:'#{provider.name}'"
    end

    def fetch_provider_klass(klass, data)
      supported_types = klass.supported_subclasses.collect(&:name)
      types_string    = supported_types.join(", ")
      unless data.key?(TYPE_ATTR)
        raise BadRequestError, "Must specify a provider type, supported types are: #{types_string}"
      end

      type = data[TYPE_ATTR]
      unless supported_types.include?(type)
        raise BadRequestError, "Invalid provider type #{type} specified, supported types are: #{types_string}"
      end
      klass.supported_subclasses.detect { |p| p.name == data[TYPE_ATTR] }
    end

    def create_provider_ddf(data)
      provider_klass = fetch_provider_klass(collection_class(:providers), data)
      endpoints = data.delete('endpoints') || []
      authentications = data.delete('authentications') || []

      validate_ddf_params(provider_klass, data.deep_dup, endpoints.deep_dup, authentications.deep_dup, true)
      provider = provider_klass.create_from_params(data, endpoints, authentications)
    rescue => err
      provider.try(:destroy)
      raise BadRequestError, "Could not create the new provider - #{err}"
    end

    def edit_provider_ddf(provider, data)
      endpoints = data.delete('endpoints') || []
      authentications = data.delete('authentications') || []

      validate_ddf_params(provider.class, data.deep_dup, endpoints.deep_dup, authentications.deep_dup)
      provider.edit_with_params(data, endpoints, authentications)
    rescue => err
      raise BadRequestError, "Could not update the provider - #{err}"
    end

    def validate_ddf_params(provider, data, endpoints, authentications, allow_type = false)
      # Convert the endpoints/authentications back to the DDF schema compatible format
      data['endpoints'] = endpoints.index_by { |endpoint| endpoint['role'] }
      data['authentications'] = authentications.index_by { |authentication| authentication['authtype'] }
      # Clean up role/authtype attributes from endpoints/authentications
      data['endpoints'].keys.each { |role| data['endpoints'].delete_path([role, 'role']) }
      data['authentications'].keys.each { |authtype| data['authentications'].delete_path([authtype, 'authtype']) }

      common_attrs = COMMON_DDF_ATTRS + (allow_type ? [TYPE_ATTR] : [])

      # Remove all valid fields from the data hash
      valid_attributes = DDF.extract_attributes(provider.params_for_create, :name) + common_attrs
      valid_attributes.each do |name|
        key_path = name.split('.')
        data.delete_path(key_path) if data.key_path?(key_path)
      end
      data.delete_blank_paths

      # Deep-traverse the hash to retrieve a list of all the invalid attributes
      invalid_keys = fetch_deep_keys(data)

      raise BadRequestError, _("Invalid attributes specified in the request: %{keys}") % {:keys => invalid_keys} if invalid_keys.any?
    end

    def create_provider(data)
      provider_klass = fetch_provider_klass(collection_class(:providers), data)
      create_data    = fetch_provider_data(provider_klass, data, :requires_zone => true)
      authorize_provider(provider_klass)
      begin
        provider = provider_klass.create!(create_data)
        update_provider_authentication(provider, data)
        provider
      rescue => err
        provider&.destroy
      raise BadRequestError, "Could not create the new provider - #{err}"
      end
    end

    def edit_provider(provider, data)
      update_data = fetch_provider_data(provider.class, data)
      provider.update(update_data) if update_data.present?
      update_provider_authentication(provider, data)
      provider
    rescue => err
      raise BadRequestError, "Could not update the provider - #{err}"
    end

    def import_vm_to_provider(provider, source_vm_id, target_params)
      desc = "#{provider_ident(provider)} importing vm"
      task_id = queue_object_action(provider, desc,
                                    :method_name => 'import_vm',
                                    :args        => [source_vm_id, target_params])
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def update_provider_authentication(provider, data)
      credentials = data[CREDENTIALS_ATTR]
      return if credentials.blank?
      all_credentials = Array.wrap(credentials).each_with_object({}) do |creds, hash|
        auth_type, creds = validate_auth_type(provider, creds)
        validate_credential_attributes(provider, creds)
        hash[auth_type.to_sym] = creds.symbolize_keys!
      end
      provider.update_authentication(all_credentials) if all_credentials.present?
    end

    def validate_auth_type(provider, creds)
      auth_type  = creds.delete(AUTH_TYPE_ATTR) || DEFAULT_AUTH_TYPE
      auth_types = provider.respond_to?(:supported_auth_types) ? provider.supported_auth_types : [DEFAULT_AUTH_TYPE]
      unless auth_types.include?(auth_type)
        raise BadRequestError, "Unsupported authentication type %s specified, %s supports: %s" %
                               [auth_type, provider.class.name, auth_types.join(", ")]
      end
      [auth_type, creds]
    end

    def validate_credential_attributes(provider, creds)
      auth_attrs    = provider.supported_auth_attributes
      invalid_attrs = creds.keys - auth_attrs
      return if invalid_attrs.blank?
      raise BadRequestError, "Unsupported credential attributes %s specified, %s supports: %s" %
                             [invalid_attrs.join(', '), provider.class.name, auth_attrs.join(", ")]
    end

    def fetch_provider_data(provider_klass, data, options = {})
      data["options"] = data["options"].deep_symbolize_keys if data.key?("options")
      provider_data = data.except(*RESTRICTED_ATTRS)
      invalid_keys  = provider_data.keys - provider_klass.columns_hash.keys - ENDPOINT_ATTRS - CONNECTION_ATTRS - provider_klass.api_allowed_attributes
      raise BadRequestError, "Invalid Provider attributes #{invalid_keys.join(', ')} specified" if invalid_keys.present?
      specify_zone(provider_data, data, options)
      provider_data
    end

    def specify_zone(provider_data, data, options)
      if data[ZONE_ATTR].present?
        provider_data[ZONE_ATTR] = fetch_zone(data)
      elsif options[:requires_zone]
        provider_data[ZONE_ATTR] = Zone.default_zone
      end
    end

    def fetch_zone(data)
      return unless data[ZONE_ATTR].present?

      zone_id = parse_id(data[ZONE_ATTR], :zone)
      raise BadRequestError, "Missing zone href or id" if zone_id.nil?
      resource_search(zone_id, :zone, Zone) # Only support Rbac allowed zone
    end

    def validate_provider_class
      param = params['provider_class']
      return unless param.present?

      raise BadRequestError, "Unsupported provider_class #{param} specified" if param != "provider"
      %w(tags policies policy_profiles).each do |cname|
        if @req.subcollection == cname || @req.expand?(cname)
          raise BadRequestError, "Management of #{cname} is unsupported for the Provider class"
        end
      end
      @collection_klasses[:providers] = Provider
    end

    def request_compliance_check(provider)
      desc = "#{provider_ident(provider)} check compliance requested"
      raise "#{provider_ident(provider)} has no compliance policies assigned" if provider.compliance_policies.blank?

      task_id = queue_object_action(provider, desc, :method_name => "check_compliance")
      action_result(true, desc, :task_id => task_id)
    rescue StandardError => err
      action_result(false, err.to_s)
    end

    def fetch_deep_keys(hash, prefix = nil)
      hash.flat_map do |key, value|
        prefixed_key = [prefix, key].compact.join('.')

        children = value.kind_of?(Hash) ? fetch_deep_keys(value, prefixed_key) : []

        [prefixed_key, *children]
      end
    end
  end
end
