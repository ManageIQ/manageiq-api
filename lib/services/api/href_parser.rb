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
      href_collection_id(path)
    end

    private

    attr_reader :href

    def path
      if href =~ /^http/
        remove_trailing_slashes(URI.parse(href).path)
      else
        path = href.dup
        path.prepend("/")     unless path.start_with?("/")
        path.prepend("/api")  unless path.start_with?("/api")
        remove_trailing_slashes(path)
      end
    end

    def remove_trailing_slashes(str)
      str.sub(/\/*$/, '')
    end

    def href_collection_id(path)
      path_array = path.split('/')
      cidx = path_array[2] && path_array[2].match(Api::VERSION_REGEX) ? 3 : 2

      collection, c_id    = path_array[cidx..cidx + 1]
      subcollection, s_id = path_array[cidx + 2..cidx + 3]

      subcollection ? [subcollection.to_sym, ApplicationRecord.uncompress_id(s_id)] : [collection.to_sym, ApplicationRecord.uncompress_id(c_id)]
    end
  end
end
