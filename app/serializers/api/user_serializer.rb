module Api
  class UserSerializer < BaseSerializer
    def self.safelist
      @safelist ||= super - %w[password_digest]
    end
  end
end
