module Api
  class BaseProviderController < BaseController
    def options
      if (id = params["id"])
        action = (@req.option_action || :update).to_sym
        render_resource_options(id, action)
      elsif (ems_id = params["ems_id"])
        render_create_resource_options(ems_id)
      else
        super
      end
    end
  end
end
