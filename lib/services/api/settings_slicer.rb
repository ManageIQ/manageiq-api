module Api
  class SettingsSlicer
    def self.slice(settings, *path)
      {}.tap do |h|
        subtree = settings.fetch_path(*path)
        h.store_path(path, subtree) if subtree
      end
    end
  end
end
