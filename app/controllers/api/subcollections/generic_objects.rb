module Api
  module Subcollections
    module GenericObjects
      def generic_objects_query_resource(object_definition)
        generic_objects = object_definition.generic_objects
        go_attrs = attribute_selection_for('generic_objects')

        return generic_objects if go_attrs.blank?

        generic_objects.collect do |go|
          attributes_hash = create_resource_attributes_hash(go_attrs, go)

          if attributes_hash['picture']
            picture = attributes_hash['picture']
            attributes_hash['picture'] = picture.attributes.merge('image_href' => picture.image_href, 'extension' => picture.extension)
          end

          go.as_json.merge(attributes_hash)
        end
      end

      def generic_objects_create_resource(object, _type, _id, data)
        create_generic_object(object, data)
      end
    end
  end
end
