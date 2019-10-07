module Api
  class ConversionHostsController < BaseController
    include Subcollections::Tags

    # Create a conversion host and enable it. This operation will run as an
    # MiqTask.
    #
    # Both the 'resource_type' and 'resource_id' are mandatory arguments,
    # and the 'resource_type' must be a supported resource type, such as
    # ManageIQ::Providers::Openstack::CloudProvider::Vm.
    #
    # You may optionally pass in the following parameters:
    #
    #   * vmware_vddk_package_url
    #   * vmware_ssh_private_key
    #   * conversion_host_ssh_private_key
    #   * openstack_tls_ca_certs
    #   * auth_user
    #
    # Example:
    #
    # POST /api/conversion_hosts {
    #   "name": "some_name",
    #   "resource_type": "ManageIQ::Providers::Redhat::InfraManager::Host",
    #   "resource_id": "7"
    #   "vmware_vddk_package_url": "some_url"
    #   "auth_user": "some_user"
    # }
    #
    def create_resource(type, id, data)
      raise BadRequestError, "resource_id must be specified" unless data['resource_id']
      raise BadRequestError, "resource_type must be specified" unless data['resource_type']
      raise BadRequestError, "auth_user must be specified" unless data['auth_user']
      raise BadRequestError, "conversion_host_ssh_private_key must be specified" unless data['conversion_host_ssh_private_key']
      raise BadRequestError, "vmware_vddk_package_url or vmware_ssh_private_key must be specified" unless data['vmware_vddk_package_url'] || data['vmware_ssh_private_key']
      raise BadRequestError, "vmware_vddk_package_url and vmware_ssh_private_key cannot both be specified" if data['vmware_vddk_package_url'] && data['vmware_ssh_private_key']

      # The scary constantize call below is mitigated by the fact that it won't get
      # past the following checks we make before passing along the params.

      resource_type = data['resource_type'].classify.safe_constantize

      raise BadRequestError, "invalid resource_type #{data['resource_type']}" unless resource_type

      collection_type = resource_type.table_name

      resource = resource_search(data['resource_id'], resource_type.to_s, collection_class(collection_type))

      raise BadRequestError, "unsupported resource_type #{resource_type}" unless resource.supports_conversion_host?

      data['resource'] = resource

      api_action(type, id) do
        begin
          message = "Enabling resource id:#{resource.id} type:#{resource.type}"
          task_id = ConversionHost.enable_queue(data.except('auth_user'), data['auth_user'])
          action_result(true, message, :task_id => task_id)
        rescue => err
          action_result(false, err.to_s)
        end
      end
    end

    # Disable the conversion host role by installing the conversion host module
    # and running the conversion host playbook that disables it, then delete
    # the conversion host record. This operation run as an MiqTask.
    #
    # You may optionally provide an 'auth_user' parameter.
    #
    # DELETE /api/conversion_hosts/:id
    # DELETE /api/conversion_hosts/:id { "auth_user": "someone" }
    #
    # Note that you can also delete via a POST action using "action: delete" as
    # a parameter, which will include a response body.
    #
    def delete_resource(type, id, data = {})
      delete_action_handler do
        conversion_host = resource_search(id, type, collection_class(type))
        message = "Disabling and deleting ConversionHost id:#{conversion_host.id} name:#{conversion_host.name}"
        begin
          task_id = conversion_host.disable_queue(data['auth_user']) # Ok if nil
          action_result(true, message, :task_id => task_id)
        rescue => err
          action_result(false, err.to_s)
        end
      end
    end
  end
end
