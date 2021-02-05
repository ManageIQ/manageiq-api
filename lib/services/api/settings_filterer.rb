module Api
  class SettingsFilterer
    def self.filter_for(user, opts = {})
      new(user, opts[:settings], opts[:whitelist]).fetch(opts.slice(:subtree))
    end

    attr_reader :user, :settings, :whitelist

    def initialize(user, settings = nil, whitelist = nil)
      @user      = user
      @settings  = settings || Settings.to_hash.deep_stringify_keys
      @whitelist = whitelist || ApiConfig.collections[:settings][:categories]
    end

    def fetch(opts = {})
      subtree = opts.fetch(:subtree, nil)

      if subtree
        slice_for(whitelisted_settings, subtree)
      else
        whitelisted_settings
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
