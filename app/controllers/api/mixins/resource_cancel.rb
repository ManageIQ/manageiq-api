module Api
  module Mixins
    module ResourceCancel
      def cancel_resource(type, id, _data)
        api_action(type, id) do |klass|
          resource_search(id, type, klass).cancel
          action_result(true, "#{klass.name} #{id} canceled")
        end
      rescue => err
        action_result(false, err.to_s)
      end
    end
  end
end
