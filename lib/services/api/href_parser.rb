module Api
  class HrefParser
    def self.parse(href)
      new(href).parse
    end

    def initialize(href)
      @href = href
    end

    def parse
      return [nil, nil] unless href
      href_collection_id
    end

    private

    attr_reader :href

    def path
      path = fully_qualified? ? URI.parse(href).path : ensure_prefix(href)
      remove_trailing_slashes(path)
    end

    def fully_qualified?
      href =~ /^http/
    end

    def remove_trailing_slashes(str)
      str.sub(/\/*$/, '')
    end

    def ensure_prefix(str)
      result = str.dup
      result.prepend("/")     unless result.start_with?("/")
      result.prepend("/api")  unless result.start_with?("/api")
      result
    end

    def href_collection_id
      cidx = path_parts[2] && path_parts[2].match(Api::VERSION_REGEX) ? 3 : 2

      collection, c_id    = path_parts[cidx..cidx + 1]
      subcollection, s_id = path_parts[cidx + 2..cidx + 3]

      subcollection ? [subcollection.to_sym, ApplicationRecord.uncompress_id(s_id)] : [collection.to_sym, ApplicationRecord.uncompress_id(c_id)]
    end

    def path_parts
      path.split("/")
    end
  end
end
