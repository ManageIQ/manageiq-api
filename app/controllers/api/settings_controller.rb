module Api
  class SettingsController < BaseController
    def index
      render_resource :settings, SettingsFilterer.filter_for(current_user)
    end

    def show
      settings = SettingsFilterer.filter_for(current_user, :subtree => @req.c_suffix)
      raise NotFoundError, "Settings entry #{@req.c_suffix} not found" if settings.empty?
      render_resource :settings, settings
    end
  end
end
