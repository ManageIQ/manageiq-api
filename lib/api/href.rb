module Api
  class Href
    # @param href [String] the href string
    #
    #   Supports the following forms:
    #   - <tt>"http://www.example.com/api"</tt>
    #   - <tt>"http://www.example.com/api/collection"</tt>
    #   - <tt>"http://www.example.com/api/collection/:cid"</tt>
    #   - <tt>"http://www.example.com/api/collection/:cid/subcollection"</tt>
    #   - <tt>"http://www.example.com/api/collection/:cid/subcollection/:sid"</tt>
    #
    #   Hrefs can also be supplied using just the path,
    #   i.e. <tt>"/api/collection/:cid"</tt>. The preceding <tt>/</tt>
    #   or <tt>/api</tt> may also be omitted, and all examples may be
    #   suffixed with a <tt>/</tt>.
    def initialize(href)
      @href = href
    end

    # @return [String, nil] the {#subcollection} if there is one,
    #   otherwise returns the {#collection}. If neither are present,
    #   returns nil
    def subject
      subcollection? ? subcollection : collection
    end

    # @return [String, nil] the {#subcollection_id} if there is one,
    #   otherwise returns the {#collection_id}. If neither are
    #   present, returns nil.
    def subject_id
      subcollection? ? subcollection_id : collection_id
    end

    # @return [String] the path portion of the href
    def path
      @path ||= remove_trailing_slashes(fully_qualified? ? URI.parse(href).path : ensure_prefix(href))
    end

    # @return [String, nil] the name of the collection if there is
    #   one, otherwise nil
    def collection
      path_segments[version? ? 3 : 2]
    end

    # @return [String, nil] the collection id if there is one,
    #   otherwise nil
    def collection_id
      path_segments[version? ? 4 : 3]
    end

    # @return [String, nil] the name of the subcollection if there is
    #   one, otherwise nil
    def subcollection
      path_segments[version? ? 5 : 4]
    end

    # @return [String, nil] the subcollection id if there is one,
    #   otherwise nil
    def subcollection_id
      path_segments[version? ? 6 : 5]
    end

    # @return true if there is a subcollection path segment,
    #   otherwise false
    def subcollection?
      !!subcollection
    end

    # @return [String, nil] the version segment from the path if there
    #   is one, otherwise nil
    def version
      path_segments[2] if version?
    end

    # @return true if there is a version segment in the path,
    #   otherwise false
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

    def path_segments
      @path_segments ||= path.split("/")
    end
  end
end
