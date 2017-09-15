module Api
  class Uncompressor
    ID_MATCHER = /(\Aid\z|_id\z)/

    def self.uncompress(body)
      return body unless body.kind_of?(Hash)
      body.each_with_object({}) do |(k, v), result|
        result[k] =
          case v
          when Array
            v.collect(&method(:uncompress))
          when Hash
            uncompress(v)
          else
            if k =~ ID_MATCHER
              ApplicationRecord.uncompress_id(v)
            else
              v
            end
          end
      end
    end
  end
end
