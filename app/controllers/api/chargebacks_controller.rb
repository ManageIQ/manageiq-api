module Api
  class ChargebacksController < BaseController
    include Subcollections::Rates
    include Api::Mixins::ChargebackAssignment
  end
end
