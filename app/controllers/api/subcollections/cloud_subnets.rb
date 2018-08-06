module Api
  module Subcollections
    module CloudSubnets
      def cloud_subnets_query_resource(object)
        object.respond_to?(:cloud_subnets) ? Array(object.cloud_subnets) : []
      end

      def cloud_subnets_create_resource(parent, _type, _id, data = {})
        data.deep_symbolize_keys!
        raise 'Must specify a name for the subnet' unless data[:name]

        begin
          message = "Creating subnet #{data[:name]}"
          task_id = queue_object_action(parent, message, :method_name => "create_cloud_subnet", :args => [data])
          action_result(true, message, :task_id => task_id)
        rescue StandardError => e
          action_result(false, e.to_s)
        end
      end
    end
  end
end
