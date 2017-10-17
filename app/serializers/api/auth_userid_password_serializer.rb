module Api
  class AuthUseridPasswordSerializer < BaseSerializer
    def self.safelist
      @safelist ||= super - %w[password]
    end
  end
end
