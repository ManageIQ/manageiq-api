module Api
  class UserSerializer < BaseSerializer
    def whitelist
      super - %w(password_digest)
    end
  end
end
