module Api
  class ActionsController < BaseController
    def create_resource(type, id, data = {})
      data["options"] = data["options"].deep_symbolize_keys if data["options"]
      super(type, id, data)
    end

    def edit_resource(type, id = nil, data = {})
      data["options"] = data["options"].deep_symbolize_keys if data["options"]
      super(type, id, data)
    end

    def options
      render_options(:actions, build_action_options)
    end

    def build_action_options
      {
        :action_types => MiqAction::TYPES,
        :snmp_trap    => MiqSnmp.available_types
      }
    end
  end
end
