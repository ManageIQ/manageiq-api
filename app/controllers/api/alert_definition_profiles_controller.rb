module Api
  class AlertDefinitionProfilesController < BaseController
    include Subcollections::AlertDefinitions

    REQUIRED_FIELDS = %w(description mode).freeze

    before_action :set_additional_attributes, :only => [:show]

    def create_resource(type, id, data = {})
      assert_all_required_fields_exists(data, type, REQUIRED_FIELDS)
      begin
        super(type, id, data)
      rescue => err
        raise BadRequestError, "Failed to create a new alert definition profile - #{err}"
      end
    end

    def edit_resource(type, id = nil, data = {})
      raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id
      begin
        super(type, id, data)
      rescue => err
        raise BadRequestError, "Failed to update alert definition profile - #{err}"
      end
    end

    def get_resource_from_href(href)
      hrefobj = Href.new(href)
      resource_search(hrefobj.subject_id, hrefobj.subject, collection_class(hrefobj.subject))
    end

    def assign_resource(type, id = nil, data = {})
      profile = resource_search(id, type, collection_class(type))
      raise BadRequestError, "Must specify either objects or tags for the assignment target" unless data.include?("objects") || data.include?("tags")
      if data.include?("objects")
        objects = data["objects"].collect do |ref|
          get_resource_from_href(ref)
        end
        profile.assign_to_objects(objects)
      end

      if data.include?("tags")
        data["tags"].each do |tag|
          profile.assign_to_tags([get_resource_from_href(tag["href"]).classification], tag["class"])
        end
      end
      profile.get_assigned_tos
    end

    def unassign_resource(type, id = nil, data = {})
      profile = resource_search(id, type, collection_class(type))
      raise BadRequestError, "Must specify either objects or tags for the assignment target" unless data.include?("objects") || data.include?("tags")

      if data.include?("objects")
        objects_to_unassign = data["objects"].collect do |ref|
          get_resource_from_href(ref)
        end
        profile.unassign_objects(objects_to_unassign)
      end

      if data.include?("tags")
        data["tags"].each do |tag|
          profile.unassign_tags(get_resource_from_href(tag["href"]).classification, tag["class"])
        end
      end

      profile.get_assigned_tos
    end

    def set_additional_attributes
      @additional_attributes = %w(get_assigned_tos)
    end
  end
end
