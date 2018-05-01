module Api
  class SettingsController < BaseController
    def index
      render_resource :settings, SettingsFilterer.filter_for(current_user)
    end

    def show
      settings_value = entry_value(SettingsFilterer.filter_for(current_user), @req.c_suffix)

      raise NotFoundError, "Settings entry #{@req.c_suffix} not found" if settings_value.nil?
      render_resource :settings, settings_entry_to_hash(@req.c_suffix, settings_value)
    end

    private

    class SettingsFilterer
      def self.filter_for(user)
        new(user).fetch
      end

      attr_reader :user

      def initialize(user)
        @user = user
      end

      def fetch
        whitelist_settings(settings_hash)
      end

      private

      def whitelist_settings(settings)
        return settings if user.super_admin_user?

        result_hash = {}
        ApiConfig.collections[:settings][:categories].each do |category_path|
          result_hash.deep_merge!(settings_entry_to_hash(category_path, entry_value(settings, category_path)))
        end
        result_hash
      end

      def settings_hash
        @settings_hash ||= Settings.to_hash.deep_stringify_keys
      end

      def entry_value(settings, path)
        settings.fetch_path(path.split('/'))
      end

      def settings_entry_to_hash(path, value)
        {}.tap { |h| h.store_path(path.split("/"), value) }
      end
    end

    def entry_value(settings, path)
      settings.fetch_path(path.split('/'))
    end

    def settings_entry_to_hash(path, value)
      {}.tap { |h| h.store_path(path.split("/"), value) }
    end
  end
end
