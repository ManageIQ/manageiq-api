module Api
  module Mixins
    module Tags
      def tag_specified(id, data)
        if id.to_i > 0
          klass  = collection_class(:tags)
          tagobj = klass.find(id)
          return tag_path_to_spec(tagobj.name).merge(:id => tagobj.id)
        end

        parse_tag(data)
      end

      def parse_tag(data)
        return {} if data.blank?

        category = data["category"]
        name     = data["name"]
        return {:category => category, :name => name} if category && name
        return tag_path_to_spec(name) if name && name[0] == '/'

        parse_tag_from_href(data)
      end

      def parse_tag_from_href(data)
        href = data["href"]
        tag  = if href&.match(%r{^.*/tags/\d+$})
                 klass = collection_class(:tags)
                 klass.find(href.split('/').last)
               end
        tag.present? ? tag_path_to_spec(tag.name).merge(:id => tag.id) : {}
      end

      def tag_path_to_spec(path)
        tag_path = path[0..7] == Api::BaseController::TAG_NAMESPACE ? path[8..-1] : path
        parts    = tag_path.split('/')
        {:category => parts[1], :name => parts[2]}
      end
    end
  end
end
