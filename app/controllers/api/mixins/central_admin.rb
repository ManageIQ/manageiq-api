module Api
  module Mixins
    module CentralAdmin
      def self.extended(klass)
        unless klass.const_defined?("MethodRelay")
          method_relay = klass.const_set("MethodRelay", Module.new)
          klass.prepend(method_relay)
        end
      end

      def central_admin(method, action = method)
        const_get("MethodRelay").class_eval do
          define_method(method) do |*meth_args, &meth_block|
            api_args = yield(*meth_args) if block_given?

            type, id, _rest = meth_args

            if ApplicationRecord.id_in_current_region?(id.to_i)
              super(*meth_args, &meth_block)
            else
              region_number = ApplicationRecord.id_to_region(id)
              Api::Mixins::CentralAdmin.inter_region_call(region_number, @req.subject.to_sym, action, api_args, id).tap do |response|
                add_href_to_result(response, type, id)
                add_task_to_result(response, response["task_href"].split("api/tasks/").last) if response["task_href"]
              end
            end
          end
        end
      end

      def self.inter_region_call(region, collection, action, api_args, id)
        InterRegionApiMethodRelay.exec_api_call(region, collection, action, api_args, id)
      rescue InterRegionApiMethodRelay::InterRegionApiMethodRelayError => error
        {"success" => false, "message" => error.message}
      end
    end
  end
end
