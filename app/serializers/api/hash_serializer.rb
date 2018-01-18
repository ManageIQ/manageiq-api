module Api
  class HashSerializer
    def self.serialize(hash)
      hash.each_with_object({}) do |(k, v), result|
        result[k.to_s] = if k.to_s == "id" || k.to_s.ends_with?("_id")
                           v.to_s
                         elsif k.to_s =~ /password/
                           nil
                         elsif v.kind_of?(Hash)
                           serialize(v)
                         else
                           v
                         end
      end.compact
    end
  end
end
