module Api
  class TasksController < BaseController
    def find_collection(klass)
      return klass.where(:userid => [current_user.userid]) if current_user.only_my_user_tasks?

      super
    end

    def find_resource(klass, key_id, id)
      return klass.find_by(key_id => id, :userid => [current_user.userid]) if current_user.only_my_user_tasks?

      super
    end
  end
end
