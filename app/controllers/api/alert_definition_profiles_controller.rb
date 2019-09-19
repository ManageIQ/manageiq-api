module Api
  class AlertDefinitionProfilesController < BaseController
    include Subcollections::AlertDefinitions
    include Api::Mixins::Tags

    REQUIRED_FIELDS = %w(description mode).freeze

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

    def assign_resource(type, id, data)
      profile = resource_search(id, type, collection_class(type))
      data['resources'].each do |resource|
        raise 'Must specify resource href' unless resource.key?('href')
        href = Href.new(resource['href'])
        if resource.key?('tag')
          profile.assign_to_tags([fetch_tag_classification_resource(resource['tag'])], href.subject)
        else
          assignable_resource = resource_search(href.subject_id, href.subject, collection_class(href.subject))
          profile.assign_to_objects([assignable_resource])
        end
      end
      action_result(true, "Assigned resources to #{alert_definition_profile_ident(profile)}")
    rescue StandardError => err
      action_result(false, "Could not assign Alert Definition Profile - #{err}")
    end

    def unassign_resource(type, id, data)
      profile = resource_search(id, type, collection_class(type))
      data['resources'].each do |resource|
        raise 'Must specify resource href' unless resource.key?('href')
        href = Href.new(resource['href'])
        if resource.key?('tag')
          profile.unassign_tags([fetch_tag_classification_resource(resource['tag'])], href.subject)
        else
          assignable_resource = resource_search(href.subject_id, href.subject, collection_class(href.subject))
          profile.unassign_objects([assignable_resource])
        end
      end
      action_result(true, "Unassigned resources from #{alert_definition_profile_ident(profile)}")
    rescue StandardError => err
      action_result(false, "Could not unassign Alert Definition Profile - #{err}")
    end

    private

    def alert_definition_profile_ident(profile)
      "Alert Definition Profile id:#{profile.id} name:'#{profile.name}'"
    end

    # rubocop:disable Rails/DynamicFindBy
    def fetch_tag_classification_resource(data)
      tag_spec = tag_specified(data["id"], data)
      raise BadRequestError, "Must specify tag id, href, or name of classification" if tag_spec.empty?
      classification = Classification.lookup_by_name(tag_spec[:category])
      classification.find_entry_by_name(tag_spec[:name])
    end
    # rubocop:enable Rails/DynamicFindBy
  end
end
