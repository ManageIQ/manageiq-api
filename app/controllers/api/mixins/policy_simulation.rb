module Api
  module Mixins
    module PolicySimulation
      def simulate_policy_collection(type, data = {})
        raise BadRequestError, "Must specify an event for policy simulation" if data["event"].blank?
        raise BadRequestError, "Must specify targets for policy simulation" if data["targets"].blank?

        target_ids = parse_collection_targets(type, data["targets"])
        klass = collection_class(type)
        invalid_ids = target_ids - klass.where(:id => target_ids).pluck(:id)
        raise "Invalid target ids #{invalid_ids.sort.join(', ')} specified for #{klass.name}" if invalid_ids.present?

        desc = "Simulating policy on event #{data["event"]} for targets [#{type}] ID: [#{target_ids.join(', ')}]"
        task_id = klass.rsop_async(data["event"], target_ids, User.current_user)
        action_result(true, desc, :task_id => task_id)
      rescue => e
        action_result(false, e.to_s)
      end

      def simulate_policy_resource(type, id, data = {})
        raise BadRequestError, "Must specify an event for policy simulation" if data["event"].blank?

        resource = resource_search(id, type, collection_class(type))

        api_action(type, id) do
          api_log_info("Simulating policy for #{resource_ident(resource)}")
          request_policy_simulation(resource, data["event"])
        end
      end

      def parse_collection_targets(type, targets)
        targets.collect do |target|
          parse_id(target, type) || parse_by_attr(target, type)
        end.compact.uniq
      end

      def request_policy_simulation(resource, event)
        desc = "#{resource_ident(resource)} simulating policy on event #{event}"
        task_id = resource.class.base_class.rsop_async(event, [resource], User.current_user)
        action_result(true, desc, :task_id => task_id)
      rescue => err
        action_result(false, err.to_s)
      end

      def resource_ident(resource)
        "#{resource.class.name.demodulize.underscore.humanize} id:#{resource.id} name: '#{resource.name}'"
      end
    end
  end
end
