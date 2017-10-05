module Api
  module Mixins
    module GenericObjects
      ADDITIONAL_ATTRS = %w(generic_object_definition associations).freeze

      private

      def create_generic_object(object_definition, data)
        object_definition.create_object(data.except(*ADDITIONAL_ATTRS)).tap do |generic_object|
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
        @additional_attributes = %w(property_attributes)
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
