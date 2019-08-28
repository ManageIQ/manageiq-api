module Api
  class SchedulesController < BaseController
    def create_resource(_type, _id, data)
      schedule = MiqSchedule.new(data)
      schedule.userid = User.current_user.userid
      schedule['run_at'] = {
        :start_time => data['run_at']['start_time'],
        :tz         => data['run_at']['tz'],
        :interval   => {:unit  => data['run_at']['interval']['unit']}
      }

      if schedule.save
        schedule
      else
        raise BadRequestError, "Failed to create new schedule - #{schedule.errors.full_messages.join(", ")}"
      end
    end
  end
end
