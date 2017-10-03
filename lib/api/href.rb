module Api
  class Href
    def initialize(href)
      @href = href
    end

    def subject
      subcollection? ? subcollection : collection
    end

    def subject_id
      subcollection? ? subcollection_id : collection_id
    end

    def path
      @path ||= remove_trailing_slashes(fully_qualified? ? URI.parse(href).path : ensure_prefix(href))
    end

    def collection
      path_segments[version? ? 3 : 2]
    end

    def collection_id
      ensure_uncompressed(path_segments[version? ? 4 : 3])
    end

    def subcollection
      path_segments[version? ? 5 : 4]
    end

    def subcollection_id
      ensure_uncompressed(path_segments[version? ? 6 : 5])
    end

    def subcollection?
      !!subcollection
    end

    def version
      path_segments[2] if version?
    end

    def version?
      @has_version ||= !!(Api::VERSION_REGEX =~ path_segments[2])
    end

    private

    attr_reader :href

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

    def ensure_uncompressed(id)
      Api.compressed_id?(id) ? Api.uncompress_id(id) : id
    end

    def path_segments
      @path_segments ||= path.split("/")
    end
  end
end
