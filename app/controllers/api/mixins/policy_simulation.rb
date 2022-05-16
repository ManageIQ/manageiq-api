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

        api_resource(type, id, "Simulating policy for") do |resource|
          {:task_id => resource.class.base_class.rsop_async(data["event"], [resource], User.current_user)}
        end
      end

      private

      def parse_collection_targets(type, targets)
        targets.collect do |target|
          parse_id(target, type) || parse_by_attr(target, type)
        end.compact.uniq
      end
    end
  end
end
