module Api
  class BaseSerializer
    def self.serialize(model, options = {})
      Environment.fetch_encrypted_attribute_names(model.class)
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
      elsif Api.time_attribute?(attr)
        return Time.at(value).utc.iso8601 if value.kind_of?(Integer)
        value.respond_to?(:utc) ? value.utc.iso8601 : value
      elsif Api.encrypted_attribute?(attr)
        nil
      else
        value
      end
    end

    def additional_attributes
      []
    end

    def whitelist
      model.attributes.keys + model.class.virtual_attribute_names + additional_attributes
    end
  end
end
