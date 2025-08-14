module Api
  # NOTE: This uses the NotificationRecipients model to then map to notifications
  class NotificationsController < BaseController
    def notifications_index_includes(scope)
      return scope unless @req.expand?(:resources)

      scope.includes(:notification => {:notification_type => {}, :subject => [:miq_requests, :services]})
    end

    def notifications_search_conditions
      {:user_id => User.current_user.id}
    end

    def find_notifications(id)
      User.current_user.notification_recipients.find(id)
    end

    def mark_as_seen_resource(type, id = nil, _data = nil)
      api_resource(type, id, "Marking as Seen") do |notification|
        action_result(notification.update_attribute(:seen, true) || false)
      end
    end
  end
end
