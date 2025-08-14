describe 'Notifications API' do
  let(:foreign_user) { FactoryBot.create(:user) }
  let(:notification) { FactoryBot.create(:notification, :initiator => @user) }
  let(:foreign_notification) { FactoryBot.create(:notification, :initiator => foreign_user) }
  let(:notification_recipient) { notification.notification_recipients.first }
  let(:notification_url) { api_notification_url(nil, notification_recipient) }
  let(:foreign_notification_url) { api_notification_url(nil, foreign_notification.notification_recipient_ids.first) }

  def query_match_regexp(*tables)
    /SELECT.*FROM\s"(?:#{tables.flatten.join("|")})"/m
  end

  describe "#index" do
    it "avoids N+1 notification queries" do
      api_basic_authorize

      query_match = query_match_regexp("notifications")
      notifications = FactoryBot.create_list(:notification, 5, :initiator => @user)

      expect {
        get api_notifications_url, :params => {
          :expand     => "resources",
          :attributes => "details"
        }
      }.to make_database_queries(:count => 1, :matching => query_match)

      expect(response.parsed_body).to include(
        "count" => 5
      )
    end

    it "only includes notifications for the current user" do
      api_basic_authorize

      notifications = FactoryBot.create_list(:notification, 2, :initiator => @user)
      notification_recipients = notifications.map { |n| n.notification_recipients.first }
      notification_hrefs = notification_recipients.map { |nr| api_notification_url(nil, nr) }

      other_user = FactoryBot.create(:user)
      other_user_notifications = FactoryBot.create_list(:notification, 1, :initiator => other_user)
      other_user_recipients = other_user_notifications.map { |n| n.notification_recipients.first }
      other_user_hrefs = other_user_recipients.map { |nr| api_notification_url(nil, nr) }

      get api_notifications_url

      # Verify the count only includes the current user's notifications
      expect(response.parsed_body).to include("count" => 2)

      # Verify the hrefs in the response match the current user's notifications
      response_hrefs = response.parsed_body["resources"].map { |r| r["href"] }
      expect(response_hrefs).to match_array(notification_hrefs)
      expect(response_hrefs & other_user_hrefs).to be_empty
    end

    it "only includes notifications for the current user with resources expanded" do
      api_basic_authorize

      notifications = FactoryBot.create_list(:notification, 2, :initiator => @user)
      notification_ids = notifications.map { |n| n.notification_recipients.first.id.to_s }

      other_user = FactoryBot.create(:user)
      other_user_notifications = FactoryBot.create_list(:notification, 1, :initiator => other_user)
      other_user_recipient_ids = other_user_notifications.map { |n| n.notification_recipients.first.id.to_s }

      get api_notifications_url, :params => {:expand => "resources"}

      # Verify the count only includes the current user's notifications
      expect(response.parsed_body).to include("count" => 2)

      # Verify the ids in the response match the current user's notifications
      response_ids = response.parsed_body["resources"].map { |r| r["id"] }
      expect(response_ids).to match_array(notification_ids)
      expect(response_ids & other_user_recipient_ids).to be_empty
    end
  end

  describe 'notification create' do
    it 'is not supported' do
      api_basic_authorize

      post(api_notifications_url, :params => gen_request(:create, :notification_id => 1, :user_id => 1))
      expect_bad_request(/Unsupported Action create/i)
    end
  end

  describe "notification read" do
    it "renders the available actions" do
      api_basic_authorize

      get(notification_url)

      expected = {
        "actions" => a_collection_including(
          a_hash_including("name" => "mark_as_seen", "method" => "post"),
          a_hash_including("name" => "delete", "method" => "post")
        )
      }
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'notification edit' do
    it 'is not supported' do
      api_basic_authorize

      post(api_notifications_url, :params => gen_request(:edit, :user_id => 1, :href => notification_url))
      expect_bad_request(/Unsupported Action edit/i)
    end
  end

  describe 'notification delete' do
    context 'on resource' do
      it 'deletes notification using POST' do
        api_basic_authorize

        post(notification_url, :params => gen_request(:delete))
        expect(response).to have_http_status(:ok)
        expect_single_action_result(:success => true, :href => api_notification_url(nil, notification_recipient))
        expect { notification_recipient.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'deletes notification using DELETE' do
        api_basic_authorize

        delete(notification_url)
        expect(response).to have_http_status(:no_content)
        expect { notification_recipient.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'on collection' do
      it 'rejects on notification that is not owned by current user' do
        api_basic_authorize

        post(api_notifications_url, :params => gen_request(:delete, :href => foreign_notification_url))
        expect(response).to have_http_status(:not_found)
      end

      it 'deletes single' do
        api_basic_authorize

        post(api_notifications_url, :params => gen_request(:delete, :href => notification_url))
        expect(response).to have_http_status(:ok)
        expect_results_to_match_hash('results', [{'success' => true,
                                                  'href'    => api_notification_url(nil, notification_recipient)}])
        expect { notification_recipient.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      let(:notification2) { FactoryBot.create(:notification, :initiator => @user) }
      let(:notification2_recipient) { notification2.notification_recipients.first }
      let(:notification2_url) { api_notification_url(nil, notification2_recipient) }

      it 'deletes multiple' do
        api_basic_authorize
        post(api_notifications_url, :params => gen_request(:delete, [{:href => notification_url}, {:href => notification2_url}]))
        expect(response).to have_http_status(:ok)
        expect { notification_recipient.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { notification2_recipient.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'mark_as_seen' do
    subject { notification_recipient.seen }
    it 'rejects on notification that is not owned by current user' do
      api_basic_authorize

      post(foreign_notification_url, :params => gen_request(:mark_as_seen))
      expect(response).to have_http_status(:not_found)
    end

    it 'marks single notification seen and returns success' do
      api_basic_authorize

      expect(notification_recipient.seen).to be_falsey
      post(notification_url, :params => gen_request(:mark_as_seen))
      expect_single_action_result(:success => true, :href => api_notification_url(nil, notification_recipient))
      expect(notification_recipient.reload.seen).to be_truthy
    end
  end
end
