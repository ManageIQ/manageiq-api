module Api
  class AuthKeyPairsController < BaseController
    def create_resource(_type, _id = nil, data = {})
      ext_management_system = ExtManagementSystem.find(data['ems_id'])

      klass = ManageIQ::Providers::CloudManager::AuthKeyPair.class_by_ems(ext_management_system)
      raise BadRequestError, klass.unsupported_reason(:create) unless klass.supports?(:create)

      task_id = klass.create_key_pair_queue(session[:userid], ext_management_system, data)
      action_result(true, "Creating Cloud Key Pair #{data['name']} for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource_main_action(type, key_pair, _data)
      ensure_supports(type, key_pair, :delete)
      {:task_id => key_pair.delete_key_pair_queue(User.current_userid)}
    end
  end
end
