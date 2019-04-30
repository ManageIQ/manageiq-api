module Api
  class PxeServersController < BaseController
    include Subcollections::PxeImages
  end
end
