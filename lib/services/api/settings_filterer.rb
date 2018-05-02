module Api
  class SettingsFilterer
    def self.filter_for(user, opts = {})
      subtree = opts.fetch(:subtree, nil)
      filterer = new(user)
      if subtree
        filterer.fetch(:subtree => subtree)
      else
        filterer.fetch
      end
    end

    attr_reader :user, :settings, :whitelist

    def initialize(user, settings = Settings.to_hash.deep_stringify_keys, whitelist = ApiConfig.collections[:settings][:categories])
      @user = user
      @settings = settings
      @whitelist = whitelist
    end

    def fetch(opts = {})
      subtree = opts.fetch(:subtree, nil)

      if subtree
        if user.super_admin_user?
          slice_for(whitelisted_settings, subtree)
        else
          slice_for(whitelisted_settings, subtree)
        end
      else
        if user.super_admin_user?
          whitelisted_settings
        else
          whitelisted_settings
        end
      end
    end

    private

    def whitelisted_settings
      if user.super_admin_user?
        settings
      else
        whitelist.each_with_object({}) do |category_path, result|
          result.deep_merge!(slice_for(settings, category_path))
        end
      end
    end

    def slice_for(settings, path)
      path = path.split("/")
      {}.tap do |h|
        subtree = settings.fetch_path(*path)
        h.store_path(path, subtree) if subtree
      end
    end
  end
end
