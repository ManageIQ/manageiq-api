module Api
  class AuthKeyPairsController < BaseController
    def create_resource(type, _id = nil, data = {})
      create_resource_task_result(type, data['ems_id'], :name => data['name']) do |ems, klass|
        klass.create_key_pair_queue(User.current_userid, ems, data) # returns task_id
      end
    end

    def delete_resource(type, id, _data = {})
      resource_task_result(type, id, :delete) do |key_pair|
        key_pair.delete_key_pair_queue(User.current_userid) # returns task_id
      end
    end
  end
end
