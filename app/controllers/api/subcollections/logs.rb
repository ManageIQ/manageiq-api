module Api
  module Subcollections
    module Logs
      def logs_query_resource(object)
        lines = (params[:lines] || 200).to_i.clamp(1, 2000)
        log_text = object.fetch_live_logs(lines)
        [
          {
            "id"      => object.id,
            "vm_id"   => object.id,
            "vm_name" => object.name,
            "vmid"    => object.ems_ref.to_s.split("/").last,
            "lines"   => lines,
            "logs"    => log_text
          }
        ]
      end
    end
  end
end
