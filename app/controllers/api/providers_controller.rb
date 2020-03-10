module Api
  class ProvidersController < BaseController
    TYPE_ATTR         = "type".freeze
    ZONE_ATTR         = "zone".freeze
    CREDENTIALS_ATTR  = "credentials".freeze
    AUTH_TYPE_ATTR    = "auth_type".freeze
    DEFAULT_AUTH_TYPE = "default".freeze
    CONNECTION_ATTRS  = %w(connection_configurations).freeze
    ENDPOINT_ATTRS    = %w(verify_ssl hostname url ipaddress port security_protocol certificate_authority).freeze
    RESTRICTED_ATTRS  = [TYPE_ATTR, CREDENTIALS_ATTR, ZONE_ATTR, "zone_id"].freeze

    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Tags
    include Subcollections::CloudNetworks
    include Subcollections::CloudSubnets
    include Subcollections::CloudTenants
    include Subcollections::CustomAttributes
    include Subcollections::LoadBalancers
    include Subcollections::SecurityGroups
    include Subcollections::Vms
    include Subcollections::Flavors
    include Subcollections::CloudTemplates
    include Subcollections::Folders
    include Subcollections::Networks
    include Subcollections::Lans

    before_action :validate_provider_class

    def create_resource(type, _id, data = {})
      assert_id_not_specified(data, type)
      raise BadRequestError, "Must specify credentials" if data[CREDENTIALS_ATTR].nil? && !data.keys.include?(*CONNECTION_ATTRS)

      create_provider(data)
    end

    def edit_resource(type, id = nil, data = {})
      raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id
      raise BadRequestError, "Provider type cannot be updated" if data.key?(TYPE_ATTR)

      provider = resource_search(id, type, collection_class(:providers))
      edit_provider(provider, data)
    end

    def refresh_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for refreshing a #{type} resource" unless id

      api_action(type, id) do |klass|
        provider = resource_search(id, type, klass)
        api_log_info("Refreshing #{provider_ident(provider)}")

        refresh_provider(provider)
      end
    end

    def delete_resource(type, id = nil, _data = nil)
      delete_action_handler do
        raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless id
        provider = resource_search(id, type, collection_class(type))
        task_id = provider.destroy_queue
        action_result(true, "#{provider_ident(provider)} deleting", :task_id => task_id, :parent_id => id)
      end
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
      providers_options = ManageIQ::Providers::BaseManager.leaf_subclasses.inject({}) do |po, ems|
        po.merge(ems.ems_type => ems.options_description)
      end

      supported_providers = ExtManagementSystem.supported_types_for_create.map do |klass|
        if klass.supports_regions?
          regions = klass.parent::Regions.all.sort_by { |r| r[:description] }.map { |r| r.slice(:name, :description) }
        end

        {
          :title   => klass.description,
          :type    => klass.to_s,
          :kind    => klass.to_s.demodulize.sub(/Manager$/, '').underscore,
          :regions => regions
        }.compact
      end

      render_options(:providers, "provider_settings" => providers_options, "supported_providers" => supported_providers)
    end

    # Process change_password action for a single resource or a collection of resources
    def change_password_resource(type, id, data = {})
      if single_resource?
        change_password(type, id, data)
      else
        change_password_multiple_providers(type, id, data)
      end
    end

    private

    def authorize_provider(typed_provider_klass)
      create_action = collection_config["providers"].collection_actions.post.detect { |a| a.name == "create" }
      provider_spec = create_action.identifiers.detect { |i| i.klass.constantize.name == typed_provider_klass.superclass.name }
      raise BadRequestError, "Unsupported request class #{typed_provider_klass}" if provider_spec.blank?

      if provider_spec.identifier && !api_user_role_allows?(provider_spec.identifier)
        raise ForbiddenError, "Create action is forbidden for #{typed_provider_klass} requests"
      end
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
      provider.update_attributes(update_data) if update_data.present?
      update_provider_authentication(provider, data)
      provider
    rescue => err
      raise BadRequestError, "Could not update the provider - #{err}"
    end

    def refresh_provider(provider)
      desc = "#{provider_ident(provider)} refreshing"
      task_ids = provider.refresh_ems(:create_task => true)
      action_result(true, desc, :task_ids => task_ids)
    rescue => err
      action_result(false, err.to_s)
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
  end
end
