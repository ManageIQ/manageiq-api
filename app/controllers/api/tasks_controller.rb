module Api
  class TasksController < BaseController
    def find_collection(klass)
      return klass.where(:userid => [current_user.userid]) if current_user.only_my_user_tasks?

      klass.all
    end

    def find_resource(klass, key_id, id)
      return klass.find_by(key_id => id, :userid => [current_user.userid]) if current_user.only_my_user_tasks?

      key_id == "id" ? klass.find(id) : klass.find_by(key_id => id)
    end
  end
end
