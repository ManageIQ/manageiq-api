module Api
  class FlavorsController < BaseController
    include Subcollections::Tags
  end
end
