module Api
  module Subcollections
    module AlertDefinitions
      def alert_definitions_query_resource(object)
        object.respond_to?(:miq_alerts) ? object.miq_alerts : []
      end

      def alert_definitions_assign_resource(object, type, id = nil, _data = nil)
        alert = resource_search(id, type, collection_class(type))
        object.add_member(alert)
        result = action_result(true, "Assigning alert_definition #{id} to profile #{object.id}")
        add_parent_href_to_result(result)
        add_subcollection_resource_to_result(result, type, alert)
      rescue => err
        action_result(false, err.to_s)
      end

      def alert_definitions_unassign_resource(object, type, id = nil, _data = nil)
        alert = resource_search(id, type, collection_class(type))
        success = object.remove_member(alert).present?
        result = action_result(success, "Unassigning alert_definition #{id} from profile #{object.id}")
        add_parent_href_to_result(result)
        add_subcollection_resource_to_result(result, type, alert)
      rescue => err
        action_result(false, err.to_s)
      end
    end
  end
end
