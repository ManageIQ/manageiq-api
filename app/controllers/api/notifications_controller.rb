module Api
  # NOTE: This uses the NotificationRecipients model to then map to notifications
  class NotificationsController < BaseController
    # based upon BaseController#index
    def index
      klass = collection_class(@req.subject)
      res, subquery_count = collection_search(@req.subcollection?, @req.subject, klass)

      res_count = (res.kind_of?(ActiveRecord::Relation) ? res.except(:select) : res).count
      expand_resources = @req.expand?(:resources)

      opts = {
        :name                  => @req.subject,
        :is_subcollection      => @req.subcollection?,
        :expand_actions        => true,
        :expand_custom_actions => false,
        :expand_resources      => expand_resources,
        :counts                => Api::QueryCounts.new(klass.count, res_count, subquery_count)
      }

      # added line
      res = res.includes(:notification => {:notification_type => {}, :subject => [:miq_requests, :services]}) if expand_resources
      # end added line

      render_collection(@req.subject, res, opts)
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
