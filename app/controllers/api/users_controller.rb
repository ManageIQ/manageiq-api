module Api
  class UsersController < BaseController
    INVALID_USER_ATTRS = %w(id href current_group_id settings current_group).freeze # Cannot update other people's settings
    INVALID_SELF_USER_ATTRS = %w(id href current_group_id current_group).freeze
    EDITABLE_ATTRS = %w(password email settings).freeze

    include Subcollections::CustomButtonEvents
    include Subcollections::Tags

    skip_before_action :validate_api_action, :only => :update

    def update
      aname = @req.action
      if aname == "edit" && !api_user_role_allows?(aname) && update_target_is_api_user?
        if (Array(@req.resource.try(:keys)) - EDITABLE_ATTRS).present?
          raise BadRequestError,
                "Cannot update attributes other than #{EDITABLE_ATTRS.join(', ')} for the authenticated user"
        end
        render_resource(:users, update_collection(:users, @req.collection_id))
      else
        validate_api_action
        super
      end
    end

    def create_resource(_type, _id, data)
      validate_user_create_data(data)
      parse_set_group(data)
      raise BadRequestError, "Must specify a valid group for creating a user" unless data["miq_groups"]
      parse_set_settings(data)
      user = collection_class(:users).create(data)
      if user.invalid?
        raise BadRequestError, "Failed to add a new user - #{user.errors.full_messages.join(', ')}"
      end
      user
    end

    def edit_resource(type, id, data)
      id == User.current_user.id ? validate_self_user_data(data) : validate_user_data(data)
      parse_set_group(data)
      parse_set_settings(data, resource_search(id, type, collection_class(type)))
      super
    end

    def delete_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for deleting a user" unless id
      raise BadRequestError, "Cannot delete user of current request" if id.to_i == User.current_user.id
      super
    end

    def set_current_group_resource(_type, id, data)
      User.current_user.tap do |user|
        raise "Can only edit authenticated user's current group" unless user.id == id
        group_id = parse_group(data["current_group"])
        raise "Must specify a current_group" unless group_id
        new_group = user.miq_groups.where(:id => group_id).first
        raise "User must belong to group" unless new_group
        # Cannot use update_attributes! due to the allowed ability to switch between groups that may have different RBAC visibility on a user's miq_groups
        user.update_attribute(:current_group, new_group)
      end
    rescue => err
      raise BadRequestError, "Cannot set current_group - #{err}"
    end

    private

    def update_target_is_api_user?
      User.current_user.id == @req.collection_id.to_i
    end

    def parse_set_group(data)
      groups = if data.key?("group")
                 group = parse_fetch_group(data.delete("group"))
                 Array(group) if group
               elsif data.key?("miq_groups")
                 data["miq_groups"].collect do |miq_group|
                   parse_fetch_group(miq_group)
                 end
               end
      data["miq_groups"] = groups if groups
    end

    def parse_set_settings(data, user = nil)
      settings = data.delete("settings")
      if settings.present?
        current_settings = user.nil? ? {} : user.settings
        data["settings"] = Hash(current_settings).deep_merge(settings.deep_symbolize_keys)
      end
    end

    def validate_user_data(data = {})
      bad_attrs = data.keys.select { |k| INVALID_USER_ATTRS.include?(k) }.compact.join(", ")
      raise BadRequestError, "Invalid attribute(s) #{bad_attrs} specified for a user" if bad_attrs.present?
      raise BadRequestError, "Users must be assigned groups" if data.key?("miq_groups") && data["miq_groups"].empty?
    end

    def validate_self_user_data(data = {})
      bad_attrs = data.keys.select { |k| INVALID_SELF_USER_ATTRS.include?(k) }.compact.join(", ")
      raise BadRequestError, "Invalid attribute(s) #{bad_attrs} specified for the current user" if bad_attrs.present?
    end

    def validate_user_create_data(data)
      validate_user_data(data)
      req_attrs = %w(name userid)
      req_attrs << "password" if ::Settings.authentication.mode == "database"
      bad_attrs = []
      req_attrs.each { |attr| bad_attrs << attr if data[attr].blank? }
      bad_attrs << "group or miq_groups" if !data['group'] && !data['miq_groups']
      raise BadRequestError, "Missing attribute(s) #{bad_attrs.join(', ')} for creating a user" if bad_attrs.present?
    end
  end
end
