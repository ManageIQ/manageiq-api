module Api
  class GenericObjectSerializer < BaseSerializer
    def self.safelist
      @safelist ||= super - %w(properties)
    end
  end
end
