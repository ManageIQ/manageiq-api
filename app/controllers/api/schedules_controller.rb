module Api
  class SchedulesController < BaseController
    def create_resource(_type, _id, data)
      validate_schedule(data)
      schedule = MiqSchedule.new(data)
      schedule.userid = User.current_user.userid

      schedule['run_at'] = {
        :start_time => data['run_at']['start_time'],
        :tz         => data['run_at']['tz'],
        :interval   => {:unit => data['run_at']['interval']['unit']}
      }

      if schedule.save
        schedule
      else
        raise BadRequestError, "Failed to create new schedule - #{schedule.errors.full_messages.join(", ")}"
      end
    end

    def validate_schedule(data)
      case data['resource_type']
      when 'MiqReport'
        validate_miq_report_schedule(data)
      when 'MiqWidget'
        validate_miq_widget_schedule(data)
      when 'DatabaseBackup'
        validate_db_backup_schedule(data)
      when 'AutomationRequest'
        validate_aut_req_schedule(data)
      when 'ContainerImage'
        validate_cont_img_schedule(data)
      end
    end

    def validate_miq_report_schedule(data)
      sched_options = data['sched_action']['options']
      if sched_options&.fetch('send_email')
        if sched_options&.fetch('email', nil).nil? || sched_options['email']&.fetch('to', nil).nil?
          raise BadRequestError, "Failed to create new schedule - #{schedule.errors.full_messages.join(", ")}"
        end
      elsif sched_options.nil?
        data['sched_action'] = {
          'method'  => data['sched_action']['method'],
          'options' => {
            'send_email'       => false,
            'email_url_prefix' => "/report/show_saved/",
            'miq_group_id'     => '2'
          }
        }

      end
    end

    def validate_miq_widget_schedule(data)
      if data['filter'].nil? || data['run_at'].nil?
        raise BadRequestError, "Failed to create new schedule - #{schedule.errors.full_messages.join(", ")}"
      end
    end

    def validate_db_backup_schedule(data)
      if data['run_at'].nil?
        raise BadRequestError, "Failed to create new schedule - #{schedule.errors.full_messages.join(", ")}"
      end
    end

    def validate_aut_req_schedule(data)
      if data['filter'].nil? || data['run_at'].nil?
        raise BadRequestError, "Failed to create new schedule - #{schedule.errors.full_messages.join(", ")}"
      end
    end

    def validate_cont_img_schedule(data)
      if data['filter'].nil? || data['run_at'].nil?
        raise BadRequestError, "Failed to create new schedule - #{schedule.errors.full_messages.join(", ")}"
      end
    end
  end
end
