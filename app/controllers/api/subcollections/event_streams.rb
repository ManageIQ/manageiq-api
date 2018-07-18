module Api
  module Subcollections
    module EventStreams
      def event_streams_query_resource(object)
        object.respond_to?(:event_where_clause) ? EventStream.where(object.event_where_clause) : []
      end
    end
  end
end
