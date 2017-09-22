module Api
  class HrefParser
    def self.parse(href)
      new(href).parse
    end

    def initialize(href)
      @href = href
    end

    def parse
      if href
        path = href.match(/^http/) ? URI.parse(href).path.sub!(/\/*$/, '') : href.dup
        path.prepend("/")     unless path.start_with?("/")
        path.prepend("/api")  unless path.match("/api")
        path.sub!(/\/*$/, '')
        return href_collection_id(path)
      end
      [nil, nil]
    end

    private

    attr_reader :href

    def href_collection_id(path)
      path_array = path.split('/')
      cidx = path_array[2] && path_array[2].match(Api::VERSION_REGEX) ? 3 : 2

      collection, c_id    = path_array[cidx..cidx + 1]
      subcollection, s_id = path_array[cidx + 2..cidx + 3]

      subcollection ? [subcollection.to_sym, ApplicationRecord.uncompress_id(s_id)] : [collection.to_sym, ApplicationRecord.uncompress_id(c_id)]
    end
  end
end
