module Api
  class SettingsController < BaseController
    def index
      render_resource :settings, SettingsFilterer.filter_for(current_user)
    end

    def show
      whitelist = SettingsFilterer.filter_for(current_user)
      path = @req.c_suffix.split("/")
      raise NotFoundError, "Settings entry #{@req.c_suffix} not found" if whitelist.fetch_path(path).nil?

      settings = SettingsSlicer.slice(whitelist, *path)
      render_resource :settings, settings
    end
  end
end
