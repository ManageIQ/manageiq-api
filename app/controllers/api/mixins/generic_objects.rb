module Api
  module Mixins
    module GenericObjects
      ADDITIONAL_ATTRS = %w(associations).freeze

      private

      def resource_custom_action_names(resource)
        (property_method_names(resource) << super).flatten
      end

      def property_method_names(resource)
        resource.respond_to?(:property_methods) ? Array(resource.property_methods) : []
      end

      def create_generic_object(object_definition, data)
        data['generic_object_definition'] = object_definition
        GenericObject.new(data.except(*ADDITIONAL_ATTRS)).tap do |generic_object|
          add_associations(generic_object, data, object_definition) if data.key?('associations')
          generic_object.save!
        end
      end

      def add_associations(generic_object, data, object_definition)
        invalid_associations = data['associations'].keys - object_definition.property_associations.keys
        raise BadRequestError, "Invalid associations #{invalid_associations.join(', ')}" unless invalid_associations.empty?

        data['associations'].each do |association, resource_refs|
          resources = resource_refs.collect do |ref|
            href = Href.new(ref['href'])
            resource_search(href.subject_id, href.subject, collection_class(href.subject))
          end
          generic_object.send("#{association}=", resources)
        end
      end

      def set_additional_attributes
        @additional_attributes = %w(property_attributes property_associations)
      end

      def set_associations
        return unless params[:associations]
        params[:associations].split(',').each do |prop|
          @additional_attributes << prop
        end
      end
    end
  end
end
