module Api
  class AutomateWorkspaceSerializer < BaseSerializer
    def coerce(attr, value)
      if attr == "input"
        HashSerializer.serialize(mask_passwords(value))
      else
        super
      end
    end

    def mask_passwords(input)
      masked = input.dup
      masked["method_parameters"].transform_values! { |v| mask_if_password(v) }
      masked["objects"].each_key do |k|
        masked["objects"][k].transform_values! { |v| mask_if_password(v)}
      end
      masked
    end

    def mask_if_password(value)
      if value.kind_of?(String) && value.start_with?("password::")
        "password::********"
      else
        value
      end
    end
  end
end
