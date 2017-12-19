module Api
  class AlertDefinitionsController < BaseController
    before_action :set_additional_attributes

    def create_resource(type, id, data = {})
      assert_id_not_specified(data, type)
      begin
        update_miq_expression(data) if data["expression"]
        alert = if data["hash_expression"]
                  super(type, id, data.deep_symbolize_keys).serializable_hash
                else
                  super(type, id, data).serializable_hash
                end
        alert.merge("expression" => alert["miq_expression"] || alert["hash_expression"])
      rescue => err
        raise BadRequestError, "Failed to create a new alert definition - #{err}"
      end
    end

    def edit_resource(type, id = nil, data = {})
      raise BadRequestError, "Must specify an id for editing a #{type} resource" unless id
      begin
        update_miq_expression(data) if data["expression"]
        if data["hash_expression"]
          super(type, id, data.deep_symbolize_keys)
        else
          super(type, id, data)
        end
      rescue => err
        raise BadRequestError, "Failed to update alert definition - #{err}"
      end
    end

    private

    def set_additional_attributes
      @additional_attributes = %w(expression)
    end

    def update_miq_expression(data)
      data["miq_expression"] = data["expression"]
      data.delete("expression")
    end
  end
end
