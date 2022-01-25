module Api
  module Mixins
    module Genealogy
      RELATIONSHIP_COLLECTIONS = %w[vms templates].freeze
      VALID_EDIT_ATTRS = %w[description name child_resources parent_resource].freeze

      def edit_resource_with_genealogy(type, id, data)
        attrs = validate_edit_data(data)
        parent, children = build_parent_children(data)
        resource_search(id, type).tap do |resource|
          resource.replace_children(children)
          resource.set_parent(parent)
          resource.update!(attrs)
        end
      end

      private

      def validate_edit_data(data)
        invalid_keys = data.keys - VALID_EDIT_ATTRS - valid_custom_attrs
        raise BadRequestError, "Cannot edit values #{invalid_keys.join(', ')}" if invalid_keys.present?

        data.except('parent_resource', 'child_resources')
      end

      def valid_custom_attrs
        Vm.virtual_attribute_names.select { |name| name =~ /custom_\d/ }
      end

      def build_parent_children(data)
        children = if data.key?('child_resources')
                     data['child_resources'].collect do |child|
                       fetch_parent_child_relationship(child['href'])
                     end
                   end

        parent_href = data.dig('parent_resource', 'href')
        parent = fetch_parent_child_relationship(parent_href) if parent_href

        [parent, Array.wrap(children)]
      end

      def fetch_parent_child_relationship(href)
        href = Href.new(href)
        raise "Invalid relationship type #{href.subject}" unless RELATIONSHIP_COLLECTIONS.include?(href.subject)

        resource_search(href.subject_id, href.subject)
      end
    end
  end
end
