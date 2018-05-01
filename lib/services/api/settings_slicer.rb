module Api
  class SettingsSlicer
    def self.slice(settings, *path)
      {}.tap { |h| h.store_path(path, settings.fetch_path(*path)) }
    end
  end
end
