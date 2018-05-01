module Api
  class SettingsFilterer
    def self.filter_for(user)
      new(user).fetch
    end

    attr_reader :user, :settings, :whitelist

    def initialize(user, settings = Settings.to_hash.deep_stringify_keys, whitelist = ApiConfig.collections[:settings][:categories])
      @user = user
      @settings = settings
      @whitelist = whitelist
    end

    def fetch
      whitelist_settings(settings)
    end

    private

    def whitelist_settings(settings)
      return settings if user.super_admin_user?

      result_hash = {}
      whitelist.each do |category_path|
        result_hash.deep_merge!(SettingsSlicer.slice(settings, *category_path.split("/")))
      end
      result_hash
    end
  end
end
