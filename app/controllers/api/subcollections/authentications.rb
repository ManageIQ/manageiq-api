module Api
  module Subcollections
    module Authentications
      def authentications_query_resource(object)
        object.respond_to?(:authentications) ? object.authentications : []
      end

      def authentications_create_resource(parent, _type, _id, data)
        task_id = AuthenticationService.create_authentication_task(parent.manager, data)
        action_result(true, 'Creating Authentication', :task_id => task_id)
      rescue => err
        action_result(false, err.to_s)
      end

      def authentications_assign_resource(parent, _type, _id, data)
        authentication_data = data.except("href").with_indifferent_access
        validate_authentication_type(authentication_data)

        parent.update_authentication(authentication_data, {:save => true})
      end

      private

      # Requires implementing valid_authentication_types in included subclass
      def validate_authentication_type(data)
        if data.keys != 1 && !valid_authentication_types.include?(data.keys.first)
          raise BadRequestError, "Invalid type specified for authentication"
        end
      end
    end
  end
end
