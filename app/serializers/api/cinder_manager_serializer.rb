module Api
  class CinderManagerSerializer < BaseSerializer
    def self.model
      ManageIQ::Providers::StorageManager
    end
  end
end
