module Api
  class AuthKeyPairsController < BaseController
    def create_resource(_type, _id = nil, data = {})
      ext_management_system = ExtManagementSystem.find(data['ems_id'])

      klass = ManageIQ::Providers::CloudManager::AuthKeyPair.class_by_ems(ext_management_system)

      raise ext_management_system.unsupported_reason(:auth_key_pair_create) unless ext_management_system.supports?(:auth_key_pair_create)

      task_id = klass.create_key_pair_queue(session[:userid], ext_management_system, data)
      action_result(true, "Creating Cloud Key Pair #{data['name']} for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource(type, id, _data = {})
      delete_action_handler do
        key_pair = resource_search(id, type, collection_class(type))
        raise "Delete not supported for #{key_pair.name}" unless key_pair.supports?(:delete)

        task_id = key_pair.delete_key_pair_queue(current_user.userid)
        action_result(true, "Deleting #{key_pair.name}", :task_id => task_id)
      end
    end
  end
end
