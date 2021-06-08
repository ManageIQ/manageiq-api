module Api
    class SnmpOptionsController < BaseController
      def options
        render_options(:snmp_options, :snmp_options_types => MiqSnmp.available_types)
      end
    end
end