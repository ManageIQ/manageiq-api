module Api
  module Mixins
    module ResourceCancel
      def cancel_resource(type, id, _data)
        api_resource(type, id, "Canceling", &:cancel)
      end
    end
  end
end
