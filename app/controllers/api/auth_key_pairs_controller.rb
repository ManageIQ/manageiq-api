module Api
  class AuthKeyPairsController < BaseController
    def delete_resource(type, id, _data = {})
      delete_action_handler do
        key_pair = resource_search(id, type, collection_class(type))
        raise "Delete not supported for #{key_pair.name}" unless key_pair.respond_to?(:delete_key_pair_queue)

        task_id = key_pair.delete_key_pair_queue(current_user.userid)
        action_result(true, "Deleting #{key_pair.name}", :task_id => task_id)
      end
    end
  end
end
