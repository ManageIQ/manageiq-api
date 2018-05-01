module Api
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
        result_hash.deep_merge!(SettingsSlicer.slice(settings_hash, *category_path.split("/")))
      end
      result_hash
    end

    def settings_hash
      @settings_hash ||= Settings.to_hash.deep_stringify_keys
    end
  end
end
