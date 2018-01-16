module Api
  class OrchestrationTemplatesController < BaseController
    def delete_resource(type, id, data = {})
      klass    = collection_class(type)
      resource = resource_search(id, type, klass)
      result = super
      resource.raw_destroy if resource.kind_of?(ManageIQ::Providers::Openstack::CloudManager::VnfdTemplate)
      result
    end

    def copy_resource(type, id, data = {})
      resource = resource_search(id, type, collection_class(type))
      resource.dup.tap do |new_resource|
        new_resource.assign_attributes(data)
        new_resource.save!
      end
    rescue => err
      raise BadRequestError, "Failed to copy orchestration template - #{err}"
    end

    DEPRECATED_TYPES = {
      'OrchestrationTemplateCfn'   => 'ManageIQ::Providers::Amazon::CloudManager::OrchestrationTemplate',
      'OrchestrationTemplateHot'   => 'ManageIQ::Providers::Openstack::CloudManager::OrchestrationTemplate',
      'OrchestrationTemplateVnfd'  => 'ManageIQ::Providers::Openstack::CloudManager::VnfdTemplate',
      'OrchestrationTemplateAzure' => 'ManageIQ::Providers::Azure::CloudManager::OrchestrationTemplate',
    }.freeze

    def create_resource(type, id, data = {})
      class_type = data['type']
      data['type'] = DEPRECATED_TYPES[class_type] || class_type

      super(type, id, data)
    end
  end
end
