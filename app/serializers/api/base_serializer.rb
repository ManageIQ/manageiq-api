module Api
  class BaseSerializer
    def self.serialize(model, options = {})
      new(model, options).serialize
    end

    attr_reader :model, :extra, :only

    def initialize(model, options = {})
      @model = model
      @extra = options.fetch(:extra, [])
      @only = options.fetch(:only, [])
    end

    def serialize
      attributes.each_with_object({}) do |a, result|
        value = coerce(a, model.public_send(a))
        result[a] = value unless value.nil?
      end
    end

    def attributes
      if only.any?
        only
      else
        model.attributes.keys + additional_attributes + extra
      end & whitelist
    end

    def coerce(attr, value)
      return if value.nil?
      if attr == "id" || attr.to_s.ends_with?("_id")
        value.to_s
      elsif %i[date datetime].include?(model.class.columns_hash[attr].try(:type))
        value.utc.iso8601
      else
        value
      end
    end

    def additional_attributes
      []
    end

    def whitelist
      model.attributes.keys + model.class.virtual_attribute_names + additional_attributes - Array(model.try(:encrypted_attributes))
    end
  end
end
