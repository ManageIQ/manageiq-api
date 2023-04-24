module Api
  module Subcollections
    module Authentications
      def authentications_query_resource(object)
        object.respond_to?(:authentications) ? object.authentications : []
      end

      def authentications_create_resource(parent, type, _id, data)
        klass = ::Authentication.descendant_get(data['type'])
        ensure_supports(type, klass, :create)

        task_id = klass.create_in_provider_queue(parent.manager.id, data.deep_symbolize_keys)
        action_result(true, 'Creating Authentication', :task_id => task_id)
      rescue => err
        action_result(false, err.to_s)
      end
    end
  end
end
