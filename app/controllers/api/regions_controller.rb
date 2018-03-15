module Api
  class RegionsController < BaseController
    private

    def resource_search(id, type, klass)
      region = MiqRegion.find_by(:region => id)
      return region unless region.nil?
      super(id, type, klass)
    end
  end
end
