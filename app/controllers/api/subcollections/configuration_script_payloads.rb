module Api
  module Subcollections
    module ConfigurationScriptPayloads
      def configuration_script_payloads_query_resource(object)
        object.configuration_script_payloads
      end

      def create_resource_configuration_script_payloads(parent, _type, _id, data)
        # When creating as a subcollection, automatically associate with parent script source
        data['configuration_script_source'] = {"id" => parent.id.to_s}
        data['manager_resource'] = {"id" => parent.manager_id.to_s} if parent.manager_id
        create_resource(:configuration_script_payloads, nil, data)
      end
    end
  end
end
