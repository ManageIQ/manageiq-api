module Api
  module Subcollections
    module CustomAttributes
      def custom_attributes_query_resource(object)
        object.respond_to?(:custom_attributes) ? object.custom_attributes : []
      end

      def custom_attributes_add_resource(object, _type, _id, data = nil)
        raise BadRequestError, "#{object.class.name} does not support management of custom attributes" unless object.respond_to?(:custom_attributes)
        data["section"] ||= "metadata"
        add_custom_attribute(object, data)
      rescue => err
        raise BadRequestError, "Could not add custom attributes - #{err}"
      end

      def custom_attributes_edit_resource(object, _type, id = nil, data = nil)
        ca = find_custom_attribute(object, id, data)
        edit_custom_attribute(object, ca, data)
      rescue => err
        raise BadRequestError, "Could not edit custom attributes - #{err}"
      end

      def custom_attributes_delete_resource(object, _type, id = nil, data = nil)
        ca = find_custom_attribute(object, id, data)
        delete_custom_attribute(object, ca)
      end

      def delete_resource_custom_attributes(parent, _type, id, data)
        ca = find_custom_attribute(parent, id, data)
        delete_custom_attribute(parent, ca)
      end

      private

      def add_custom_attribute(object, data)
        ca = find_custom_attribute_by_data(object, data)
        if ca.present?
          update_custom_attributes(ca, data)
        else
          ca = new_custom_attribute(data)
          object.custom_attributes << ca
        end
        update_custom_field(object, ca)
        ca
      end

      def edit_custom_attribute(object, ca, data)
        return if ca.blank?
        data = format_custom_attributes(data)
        update_custom_attributes(ca, data)
        update_custom_field(object, ca)
        ca
      end

      def delete_custom_attribute(object, ca)
        return if ca.blank?
        object.set_custom_field(ca.name, '') if ca.stored_on_provider?
        ca.delete
        ca
      end

      def update_custom_attributes(ca, data)
        data = format_custom_attributes(data)
        ca.update(data.slice("name", "value", "section"))
      end

      def update_custom_field(object, ca)
        object.set_custom_field(ca.name.to_s, ca.value.to_s) if ca.stored_on_provider?
      end

      def find_custom_attribute(object, id, data)
        if object.respond_to?(:custom_attributes)
          id.present? && id > 0 ? object.custom_attributes.find(id) : find_custom_attribute_by_data(object, data)
        else
          raise BadRequestError, "#{object.class.name} does not support management of custom attributes"
        end
      end

      def find_custom_attribute_by_data(object, data)
        object.custom_attributes.detect do |ca|
          ca.section.to_s == data["section"].to_s && ca.name.downcase == data["name"].downcase
        end
      end

      def new_custom_attribute(data)
        data["source"] ||= "EVM"
        raise "Must specify a name for a custom attribute to be added" if data["name"].blank?
        data = format_custom_attributes(data)
        CustomAttribute.new(data)
      end

      def format_custom_attributes(attribute)
        if CustomAttribute::ALLOWED_API_VALUE_TYPES.include?(attribute["field_type"])
          attribute["value"] = attribute.delete("field_type").safe_constantize.parse(attribute["value"])
        end
        if attribute["section"].present? && !CustomAttribute::ALLOWED_API_SECTIONS.include?(attribute["section"])
          raise "Invalid attribute section specified: #{attribute["section"]}"
        end
        attribute
      end
    end
  end
end
