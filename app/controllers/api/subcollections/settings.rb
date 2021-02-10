module Api
  module Subcollections
    module Settings
      def settings
        id       = @req.collection_id
        type     = @req.collection
        klass    = collection_class(@req.collection)
        resource = resource_search(id, type, klass)

        case @req.method
        when :patch
          raise ForbiddenError, "You are not authorized to edit settings." unless super_admin?

          begin
            resource.add_settings_for_resource(@req.json_body)
          rescue Vmdb::Settings::ConfigurationInvalid => err
            raise BadRequestError, "Settings validation failed - #{err}"
          end
        when :delete
          raise ForbiddenError, "You are not authorized to remove settings." unless super_admin?

          resource.remove_settings_path_for_resource(*@req.json_body)
          head :no_content
          return
        end

        render_resource :settings, resource_settings(resource)
      end

      def settings_query_resource(resource)
        resource_settings(resource)
      end

      private

      def resource_settings(resource)
        if super_admin? || current_user.role_allows?(:identifier => 'ops_settings')
          filter_opts           = {:settings => resource.settings_for_resource.to_hash.deep_stringify_keys}
          filter_opts[:subtree] = @req.c_suffix if @req.method == :get

          SettingsFilterer.filter_for(current_user, filter_opts)
        else
          raise ForbiddenError, "You are not authorized to view settings."
        end
      end
    end
  end
end
