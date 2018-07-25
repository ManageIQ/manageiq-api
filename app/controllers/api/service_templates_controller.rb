module Api
  class ServiceTemplatesController < BaseController
    include Api::Mixins::Pictures
    include Api::Mixins::ServiceTemplates
    include Subcollections::ResourceActions
    include Subcollections::Schedules
    include Subcollections::ServiceDialogs
    include Subcollections::ServiceRequests
    include Subcollections::Tags

    before_action :set_additional_attributes, :only => [:show]

    alias fetch_service_templates_picture fetch_picture

    def create_resource(_type, _id, data)
      catalog_item_type = ServiceTemplate.class_from_request_data(data)
      catalog_item_type.create_catalog_item(data.deep_symbolize_keys, User.current_user.userid)
    rescue => err
      raise BadRequestError, "Could not create Service Template - #{err}"
    end

    def edit_resource(type, id, data)
      catalog_item = resource_search(id, type, collection_class(:service_templates))
      catalog_item.update_catalog_item(data.deep_symbolize_keys, User.current_user.userid)
    rescue => err
      raise BadRequestError, "Could not update Service Template - #{err}"
    end

    def order_resource(_type, id, data)
      order_service_template(id, data)
    end

    def archive_resource(type, id, _data)
      service_template = resource_search(id, type, collection_class(type))
      service_template.archive!
      action_result(true, "Archived Service Template")
    rescue => err
      action_result(false, "Could not archive Service Template - #{err}")
    end

    def unarchive_resource(type, id, _data)
      service_template = resource_search(id, type, collection_class(type))
      service_template.unarchive!
      action_result(true, "Unarchived Service Template")
    rescue => err
      action_result(false, "Could not unarchive Service Template - #{err}")
    end

    private

    def set_additional_attributes
      @additional_attributes = %w(config_info)
    end
  end
end
