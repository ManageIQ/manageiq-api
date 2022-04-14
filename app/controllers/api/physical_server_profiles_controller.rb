module Api
  class PhysicalServerProfilesController < BaseController
    include Subcollections::EventStreams



    private

    def ensure_resource_exists(type, id)
      raise NotFoundError, "#{type} with id:#{id} not found" unless collection_class(type).exists?(id)
    end
  end
end
