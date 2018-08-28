module Api
  class ServiceOfferingsController < BaseController
    def service_parameters_sets_query_resource(object)
      object.service_parameters_sets
    end
  end
end
