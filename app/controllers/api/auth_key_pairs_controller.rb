module Api
  class AuthKeyPairsController < BaseController
    def create_resource(type, _id = nil, data = {})
      create_ems_resource(type, data, :supports => true) do |ext_management_system, klass|
        {:task_id => klass.create_key_pair_queue(User.current_userid, ext_management_system, data)}
      end
    end

    def delete_resource_main_action(type, key_pair, _data)
      ensure_supports(type, key_pair, :delete)
      {:task_id => key_pair.delete_key_pair_queue(User.current_userid)}
    end
  end
end
