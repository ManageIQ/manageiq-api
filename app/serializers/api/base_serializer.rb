module Api
  class BaseSerializer
    def self.serialize(model, options = {})
      new(model, options).serialize
    end

    def self.model
      @model ||= name.demodulize.sub(/Serializer/, "").safe_constantize
    end

    def self.primary_key
      @primary_key ||= model.primary_key
    end

    def self.foreign_keys
      @foreign_keys ||= %i(belongs_to has_one).flat_map { |type| model.reflect_on_all_associations(type).collect(&:foreign_key) }
    end

    def self.attributes
      @attributes ||= model.column_names
    end

    def self.virtual_attributes
      @virtual_attributes ||= model.virtual_attribute_names
    end

    def self.additional_attributes
      @additional_attributes ||= []
    end

    def self.date_or_time_attributes
      @date_or_time_attributes ||= Set.new(model.columns_hash.select { |_k, v| v.type.in?(%i(date datetime)) }.collect(&:first))
    end

    def self.encrypted_attributes
      @encrypted_attributes ||= Array(model.try(:encrypted_attributes))
    end

    def self.safelist
      @safelist ||= attributes + virtual_attributes + additional_attributes - encrypted_attributes
    end

    attr_reader :model, :extra, :only

    def initialize(model, options = {})
      @model = model
      @extra = options.fetch(:extra, [])
      @only = options.fetch(:only, [])
    end

    def serialize
      attributes.each_with_object({}) { |a, result| result[a] = coerce(a, model.public_send(a)) }.compact
    end

    def attributes
      (only.any? ? only : default_attributes) & self.class.safelist
    end

    def default_attributes
      self.class.attributes + self.class.additional_attributes + extra
    end

    def coerce(attr, value)
      return if value.nil?
      if key?(attr)
        value.to_s
      elsif date_or_time?(attr)
        value.utc.iso8601
      elsif value.kind_of?(Hash)
        HashSerializer.serialize(value)
      else
        value
      end
    end

    def key?(attribute)
      self.class.primary_key == attribute || self.class.foreign_keys.include?(attribute)
    end

    def date_or_time?(attribute)
      self.class.date_or_time_attributes.include?(attribute)
    end
  end
end
