module Api
  class AuthenticationSerializer < BaseSerializer
    def self.safelist
      @safelist ||= super - %w(password)
    end
  end
end
