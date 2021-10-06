# Rest API Request Tests - Users specs
#
# - Creating a user                      /api/users                           POST
# - Creating a user via action           /api/users                           action "create"
# - Creating multiple user               /api/users                           action "create"
# - Edit a user                          /api/users/:id                       action "edit"
# - Edit multiple users                  /api/users                           action "edit"
# - Delete a user                        /api/users/:id                       DELETE
# - Delete a user by action              /api/users/:id                       action "delete"
# - Delete multiple users                /api/users                           action "delete"
#
RSpec.describe "users API" do
  let(:expected_attributes) { %w(id name userid current_group_id) }

  let(:tenant1)  { FactoryBot.create(:tenant, :name => "Tenant1") }
  let(:role1)    { FactoryBot.create(:miq_user_role) }
  let(:group1)   { FactoryBot.create(:miq_group, :description => "Group1", :role => role1, :tenant => tenant1) }

  let(:role2)    { FactoryBot.create(:miq_user_role) }
  let(:group2)   { FactoryBot.create(:miq_group, :description => "Group2", :role => role2, :tenant => tenant1) }

  let(:sample_user1) { {:userid => "user1", :name => "User1", :password => "password1", :group => {"id" => group1.id}} }
  let(:sample_user2) { {:userid => "user2", :name => "User2", :password => "password2", :group => {"id" => group2.id}} }
  let(:sample_user3) { {:userid => "user3", :name => "User3", :password => "password3", :miq_groups => [{"id" => group1.id}, {"id" => group2.id}]} }

  let(:user1) { FactoryBot.create(:user, sample_user1.except(:group).merge(:miq_groups => [group1])) }
  let(:user2) { FactoryBot.create(:user, sample_user2.except(:group).merge(:miq_groups => [group2])) }

  before do
    @user.miq_groups << group1
    @user.miq_groups << group2
  end

  context "with an appropriate role" do
    it "can change the user's password" do
      api_basic_authorize action_identifier(:users, :edit)

      expect do
        post api_user_url(nil, @user), :params => gen_request(:edit, :password => "new_password")
      end.to change { @user.reload.password_digest }

      expect(response).to have_http_status(:ok)
    end

    it "can change another user's password" do
      api_basic_authorize action_identifier(:users, :edit)
      user = FactoryBot.create(:user, :miq_groups => [group1], :current_group => group1)

      expect do
        post api_user_url(nil, user), :params => gen_request(:edit, :password => "new_password")
      end.to change { user.reload.password_digest }

      expect(response).to have_http_status(:ok)
    end
  end

  context "without an appropriate role" do
    it "can change the user's own password" do
      api_basic_authorize

      expect do
        post api_user_url(nil, @user), :params => gen_request(:edit, :password => "new_password")
      end.to change { @user.reload.password_digest }

      expect(response).to have_http_status(:ok)
    end

    it "can change the user's own email" do
      api_basic_authorize action_identifier(:users, :edit)

      expect do
        post api_user_url(nil, @user), :params => gen_request(:edit, :email => "tom@cartoons.com")
      end.to change { @user.reload.email }

      expect(response).to have_http_status(:ok)
    end

    it "can change the user's own settings" do
      api_basic_authorize action_identifier(:users, :edit)

      expect do
        post api_user_url(nil, @user), :params => gen_request(:edit, :settings => {:cartoon => {:tom_jerry => 'y'}})
      end.to change { @user.reload.settings }

      expect(response).to have_http_status(:ok)
    end

    it "will not allow the changing of attributes other than the password, email or settings" do
      api_basic_authorize

      expect do
        post api_user_url(nil, @user), :params => gen_request(:edit, :name => "updated_name")
      end.not_to change { @user.reload.name }

      expect(response).to have_http_status(:bad_request)
    end

    it "will not allow the user to change their own group" do
      api_basic_authorize

      expect do
        post api_user_url(nil, @user), :params => gen_request(:edit, :group => "updated_name")
      end.not_to change { @user.reload.name }

      expect(response).to have_http_status(:bad_request)
    end

    it "cannot change another user's password" do
      api_basic_authorize
      user = FactoryBot.create(:user)

      expect do
        post api_user_url(nil, user), :params => gen_request(:edit, :password => "new_password")
      end.not_to change { user.reload.password_digest }

      expect(response).to have_http_status(:forbidden)
    end

    it "cannot change another user's settings" do
      api_basic_authorize
      user = FactoryBot.create(:user, :settings => {:locale => "en"})

      expect do
        post api_user_url(nil, user), :params => gen_request(:edit, :settings => {:locale => "ja"})
      end.not_to change { user.reload.settings }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "users create" do
    it "rejects creation without appropriate role" do
      api_basic_authorize

      post(api_users_url, :params => sample_user1)

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects user creation with id specified" do
      api_basic_authorize collection_action_identifier(:users, :create)

      post(api_users_url, :params => { "userid" => "userid1", "id" => 100 })

      expect_bad_request(/id or href should not be specified/i)
    end

    it "rejects user creation with invalid group specified" do
      api_basic_authorize collection_action_identifier(:users, :create)

      post(api_users_url, :params => sample_user2.merge("group" => {"id" => 999_999}))

      expect(response).to have_http_status(:not_found)
    end

    it "rejects user creation with missing attribute" do
      api_basic_authorize collection_action_identifier(:users, :create)

      post(api_users_url, :params => sample_user2.except(:userid))

      expect_bad_request(/Missing attribute/i)
    end

    it "supports single user creation" do
      api_basic_authorize collection_action_identifier(:users, :create)

      post(api_users_url, :params => sample_user1)

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)

      user_id = response.parsed_body["results"].first["id"]
      expect(User.exists?(user_id)).to be_truthy
    end

    it "supports single user creation via action" do
      api_basic_authorize collection_action_identifier(:users, :create)

      post(api_users_url, :params => gen_request(:create, sample_user1))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)

      user_id = response.parsed_body["results"].first["id"]
      expect(User.exists?(user_id)).to be_truthy
    end

    it "supports multiple user creation" do
      api_basic_authorize collection_action_identifier(:users, :create)

      post(api_users_url, :params => gen_request(:create, [sample_user1, sample_user2]))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)

      results = response.parsed_body["results"]
      user1_hash, user2_hash = results.first, results.second
      expect(User.exists?(user1_hash["id"])).to be_truthy
      expect(User.exists?(user2_hash["id"])).to be_truthy
      expect(user1_hash["current_group_id"]).to eq(group1.id.to_s)
      expect(user2_hash["current_group_id"]).to eq(group2.id.to_s)
    end

    it "supports creating user with multiple groups" do
      api_basic_authorize collection_action_identifier(:users, :create)

      post(api_users_url, :params => gen_request(:create, sample_user3))

      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys("results", expected_attributes)

      user_id = response.parsed_body["results"].first["id"]
      expect(User.exists?(user_id)).to be_truthy
    end

    it "rejects user creation with missing group attribute" do
      api_basic_authorize collection_action_identifier(:users, :create)

      post(api_users_url, :params => sample_user2.except(:group))

      expect_bad_request(/Missing attribute/i)
    end

    it "rejects user creation with missing miq_groups attribute" do
      api_basic_authorize collection_action_identifier(:users, :create)

      post(api_users_url, :params => sample_user3.except(:miq_groups))

      expect_bad_request(/Missing attribute/i)
    end
  end

  describe "users edit" do
    it "allows for setting of multiple miq_groups" do
      api_basic_authorize collection_action_identifier(:users, :edit)

      request = {
        "action"    => "edit",
        "resources" => [{
          "href"       => api_user_url(nil, user1),
          "miq_groups" => [
            { "id" => group2.id.to_s },
            { "href" => api_group_url(nil, group1) }
          ]
        }]
      }
      post(api_users_url, :params => request)

      expect(response).to have_http_status(:ok)
      expect(user1.reload.miq_groups).to match_array([group2, group1])
    end

    it "does not allow edits of current_user" do
      api_basic_authorize collection_action_identifier(:users, :edit)

      request = {
        "action"    => "edit",
        "resources" => [{
          "href"          => api_user_url(nil, user1),
          "current_group" => {}
        }]
      }
      post(api_users_url, :params => request)

      expected = {
        'error' => a_hash_including(
          'message' => "Invalid attribute(s) current_group specified for a user"
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it "does not allow setting of empty miq_groups" do
      api_basic_authorize collection_action_identifier(:users, :edit)

      request = {
        "action"    => "edit",
        "resources" => [{
          "href"       => api_user_url(nil, user1),
          "miq_groups" => []
        }]
      }
      post(api_users_url, :params => request)

      expected = {
        'error' => a_hash_including(
          'message' => 'Users must be assigned groups'
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it "rejects user edits without appropriate role" do
      api_basic_authorize

      post(api_users_url, :params => gen_request(:edit, "name" => "updated name", "href" => api_user_url(nil, user1)))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects user edits for invalid resources" do
      api_basic_authorize collection_action_identifier(:users, :edit)

      post(api_user_url(nil, 999_999), :params => gen_request(:edit, "name" => "updated name"))

      expect(response).to have_http_status(:not_found)
    end

    it "supports single user edit" do
      api_basic_authorize collection_action_identifier(:users, :edit)

      post(api_user_url(nil, user1), :params => gen_request(:edit, "name" => "updated name"))

      expect_single_resource_query("id" => user1.id.to_s, "name" => "updated name")
      expect(user1.reload.name).to eq("updated name")
    end

    it "supports single user edit of other attributes including group change" do
      api_basic_authorize collection_action_identifier(:users, :edit)

      post(api_user_url(nil, user1), :params => gen_request(:edit,
                                                            "email" => "user1@email.com",
                                                            "group" => {"description" => group2.description}))

      expect_single_resource_query("id" => user1.id.to_s, "email" => "user1@email.com", "current_group_id" => group2.id.to_s)
      expect(user1.reload.email).to eq("user1@email.com")
      expect(user1.reload.current_group_id).to eq(group2.id)
    end

    it "supports multiple user edits" do
      api_basic_authorize collection_action_identifier(:users, :edit)

      post(api_users_url, :params => gen_request(:edit,
                                                 [{"href" => api_user_url(nil, user1), "first_name" => "John"},
                                                  {"href" => api_user_url(nil, user2), "first_name" => "Jane"}]))

      expect_results_to_match_hash("results",
                                   [{"id" => user1.id.to_s, "first_name" => "John"},
                                    {"id" => user2.id.to_s, "first_name" => "Jane"}])

      expect(user1.reload.first_name).to eq("John")
      expect(user2.reload.first_name).to eq("Jane")
    end
  end

  describe "users delete" do
    it "rejects user deletion, by post action, without appropriate role" do
      api_basic_authorize

      post(api_users_url, :params => gen_request(:delete, "href" => api_user_url(nil, 100)))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects user deletion without appropriate role" do
      api_basic_authorize

      delete(api_user_url(nil, 100))

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects user deletes for invalid users" do
      api_basic_authorize collection_action_identifier(:users, :delete)

      delete(api_user_url(nil, 999_999))

      expect(response).to have_http_status(:not_found)
    end

    it "rejects user delete of requesting user via action" do
      api_basic_authorize collection_action_identifier(:users, :delete)

      post(api_users_url, :params => gen_request(:delete, "href" => api_user_url(nil, @user)))

      expect_bad_request("Cannot delete user of current request")
    end

    it "rejects user delete of requesting user" do
      api_basic_authorize collection_action_identifier(:users, :delete)

      delete(api_user_url(nil, @user))

      expect_bad_request("Cannot delete user of current request")
    end

    it "supports single user delete" do
      api_basic_authorize collection_action_identifier(:users, :delete)

      user1_id = user1.id
      delete(api_user_url(nil, user1_id))

      expect(response).to have_http_status(:no_content)
      expect(User.exists?(user1_id)).to be_falsey
    end

    it "supports single user delete action" do
      api_basic_authorize collection_action_identifier(:users, :delete)

      user1_id = user1.id
      user1_url = api_user_url(nil, user1_id)

      post(user1_url, :params => gen_request(:delete))

      expect_single_action_result(:success => true, :message => "Deleting User", :href => api_user_url(nil, user1))
      expect(User.exists?(user1_id)).to be_falsey
    end

    it "supports multiple user deletes" do
      api_basic_authorize collection_action_identifier(:users, :delete)

      user1_id, user2_id = user1.id, user2.id
      user1_url, user2_url = api_user_url(nil, user1_id), api_user_url(nil, user2_id)

      post(api_users_url, :params => gen_request(:delete, [{"href" => user1_url}, {"href" => user2_url}]))

      expect_multiple_action_result(2)
      expect_result_resources_to_include_hrefs("results", [api_user_url(nil, user1), api_user_url(nil, user2)])
      expect(User.exists?(user1_id)).to be_falsey
      expect(User.exists?(user2_id)).to be_falsey
    end
  end

  describe "tags subcollection" do
    let(:user) { FactoryBot.create(:user, :miq_groups => [group1], :current_group => group1) }

    let(:tag1)         { {:category => "department", :name => "finance", :path => "/managed/department/finance"} }
    let(:tag2)         { {:category => "cc",         :name => "001",     :path => "/managed/cc/001"} }

    let(:invalid_tag_url) { api_tag_url(nil, 999_999) }

    before do
      FactoryBot.create(:classification_department_with_tags)
      FactoryBot.create(:classification_cost_center_with_tags)
    end

    it "can list a user's tags" do
      Classification.classify(user, tag1[:category], tag1[:name])
      api_basic_authorize

      get(api_user_tags_url(nil, user))

      expect(response.parsed_body).to include("subcount" => 1)
      expect(response).to have_http_status(:ok)
    end

    it "can assign a tag to a user" do
      api_basic_authorize(subcollection_action_identifier(:users, :tags, :assign))

      post(api_user_tags_url(nil, user), :params => { :action => "assign", :category => "department", :name => "finance" })

      expected = {
        "results" => [
          a_hash_including(
            "success"      => true,
            "message"      => a_string_matching(/assigning tag/i),
            "tag_category" => "department",
            "tag_name"     => "finance"
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can unassign a tag from a user" do
      Classification.classify(user, tag1[:category], tag1[:name])
      api_basic_authorize(subcollection_action_identifier(:users, :tags, :unassign))

      post(api_user_tags_url(nil, user), :params => { :action => "unassign", :category => "department", :name => "finance" })

      expected = {
        "results" => [
          a_hash_including(
            "success"      => true,
            "message"      => a_string_matching(/unassigning tag/i),
            "tag_category" => "department",
            "tag_name"     => "finance"
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "assigns multiple tags to a User" do
      api_basic_authorize subcollection_action_identifier(:users, :tags, :assign)

      post(api_user_tags_url(nil, user), :params => gen_request(:assign, [{:name => tag1[:path]}, {:name => tag2[:path]}]))

      expect_tagging_result(
        [{:success => true, :href => api_user_url(nil, user), :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => api_user_url(nil, user), :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      )
    end

    it "assigns tags by mixed specification to a User" do
      api_basic_authorize subcollection_action_identifier(:users, :tags, :assign)

      tag = Tag.find_by(:name => tag2[:path])
      post(api_user_tags_url(nil, user), :params => gen_request(:assign, [{:name => tag1[:path]}, {:href => api_tag_url(nil, tag)}]))

      expect_tagging_result(
        [{:success => true, :href => api_user_url(nil, user), :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => api_user_url(nil, user), :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      )
    end

    it "unassigns multiple tags from a User" do
      Classification.classify(user, tag2[:category], tag2[:name])

      api_basic_authorize subcollection_action_identifier(:users, :tags, :unassign)

      tag = Tag.find_by(:name => tag2[:path])
      post(api_user_tags_url(nil, user), :params => gen_request(:unassign, [{:name => tag1[:path]}, {:href => api_tag_url(nil, tag)}]))

      expect_tagging_result(
        [{:success => true, :href => api_user_url(nil, user), :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => api_user_url(nil, user), :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      )
      expect(user.tags.count).to eq(0)
    end
  end

  describe "set_current_group" do
    it "can set the current group from the user's miq_groups" do
      api_basic_authorize

      post(api_user_url(nil, @user), :params => {
             :action        => "set_current_group",
             :current_group => { :href => api_group_url(nil, group2) }
           })

      expected = {
        "current_group_id" => group2.id.to_s
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "requires that the user belong to the current group" do
      group3 = FactoryBot.create(:miq_group)
      api_basic_authorize

      post(api_user_url(nil, @user), :params => {
             :action        => "set_current_group",
             :current_group => { :href => api_group_url(nil, group3) }
           })

      expected = {
        "error" => a_hash_including(
          "kind"    => "bad_request",
          "message" => "Cannot set current_group - User must belong to group"
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it "requires the current group to be specified" do
      api_basic_authorize

      post(api_user_url(nil, @user), :params => {:action => "set_current_group"})

      expected = {
        "error" => a_hash_including(
          "kind"    => "bad_request",
          "message" => "Cannot set current_group - Must specify a current_group"
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it "only allows editing of the validated user's groups" do
      api_basic_authorize

      post(api_user_url(nil, user1), :params => {:action => "set_current_group"})

      expected = {
        "error" => a_hash_including(
          "kind"    => "bad_request",
          "message" => "Cannot set current_group - Can only edit authenticated user's current group"
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'GET /users/:id/custom_button_events' do
    let(:super_admin) { FactoryBot.create(:user, :role => 'super_administrator', :userid => 'alice', :password => 'alicepassword') }
    let!(:custom_button_event) { FactoryBot.create(:custom_button_event, :target => user1) }

    it 'returns with the custom button events for the given user' do
      api_basic_authorize(:user => super_admin.userid, :password => super_admin.password)

      get(api_user_custom_button_events_url(nil, user1))

      expected = {
        "name"      => "custom_button_events",
        "count"     => 1,
        "resources" => contain_exactly(
          a_hash_including(
            'href' => a_string_matching("custom_button_events/#{custom_button_event.id}")
          )
        )
      }

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  context "Revoking Sessions" do
    before do
      # Keep this outside of the loop below with the `let` providing the value
      # for the stub, otherwise it will not work as expected
      stub_settings_merge(:server => {:session_store => session_store_value})
      TokenStore.token_caches.clear
    end

    after { TokenStore.token_caches.clear }

    %w[cache sql memory].each do |session_store|
      let(:session_store_value) { session_store }

      it "revokes all own sessions of authenticated user with #{session_store}" do
        api_basic_authorize

        FactoryBot.create(:session, :user_id => @user.id)
        expect(Session.where(:user_id => @user.id).count).to eq(1)

        ts = TokenStore.acquire("api", 100)

        ts.create_user_token("my_token", {:userid => @user.userid, :expires_on => Time.zone.now + 100.days}, {:expires_in => 100})

        expect(ts.read("my_token")).not_to be_nil

        if ::Settings.server.session_store == "sql"
          expect(ts.read("my_token")[:userid]).to eq(@user.userid)
        else
          expect(ts.read("tokens_for_#{@user.userid}")).not_to be_nil
        end

        ts.create_user_token("his_token", {:userid => user1.userid, :expires_on => Time.zone.now + 100.days}, {:expires_in => 100})
        expect(ts.read("his_token")).not_to be_nil

        if ::Settings.server.session_store == "sql"
          expect(ts.read("my_token")[:userid]).to eq(@user.userid)
        else
          expect(ts.read("tokens_for_#{@user.userid}")).not_to be_nil
        end

        post(api_users_url, :params => {'action' => "revoke_sessions"})

        expect(Session.where(:user_id => @user.id).count).to eq(0)

        expect(response).to have_http_status(:ok)
        expect(ts.read("my_token")).to be_nil

        unless ::Settings.server.session_store == "sql"
          expect(ts.read("tokens_for_#{@user.userid}")).to be_nil
        end

        expect(ts.read("his_token")).not_to be_nil

        unless ::Settings.server.session_store == "sql"
          expect(ts.read("tokens_for_#{user1.userid}")).not_to be_nil
        end
      end

      context "target user is other than authenticated user with #{session_store}" do
        it "revokes sessions of resource user" do
          api_basic_authorize :revoke_user_sessions
          user1.miq_groups << @user.miq_groups.first
          user1.save

          post(api_user_url(nil, user1), :params => {'action' => "revoke_sessions"})

          expect(response).to have_http_status(:ok)

          expect(response.parsed_body["success"]).to be_truthy
          expect(response.parsed_body["message"]).to eq("All sessions revoked successfully for user #{user1.userid}.")
        end

        it "doesn't allow to revoke resource user sessions when authenticated user doesn't have access to resource user due to RBAC" do
          api_basic_authorize :revoke_user_sessions

          post(api_user_url(nil, user_admin), :params => {'action' => "revoke_sessions"})

          expect(response.parsed_body["success"]).to be_falsey
          expect(response.parsed_body["message"]).to eq("Access to the resource users/#{user_admin.id} is forbidden")
        end

        it "doesn't allow to revoke resource user sessions when authenticated user doesn't have access to resource user due to missing entitlement" do
          api_basic_authorize
          user1.miq_groups << @user.miq_groups.first
          user1.save

          post(api_user_url(nil, user1), :params => {'action' => "revoke_sessions"})

          expect(response.parsed_body["success"]).to be_falsey
          expect(response.parsed_body["message"]).to eq("The user is not authorized for this task or item.")
        end

        let(:user_admin) do
          User.all.detect(&:super_admin_user?) || FactoryBot.create(:user_admin, :userid => "admin")
        end

        it "does allow to revoke resource user sessions when authenticated user is super_admin" do
          api_basic_authorize
          @user = user_admin
          User.current_user = user_admin
          allow(User).to receive(:current_user).and_return(user_admin)

          post(api_user_url(nil, user1), :params => {'action' => "revoke_sessions"})

          expect(response.parsed_body["success"]).to be_truthy
          expect(response.parsed_body["message"]).to eq("All sessions revoked successfully for user #{user1.userid}.")
        end

        let!(:user3) { FactoryBot.create(:user, :userid => "userX") }

        let!(:resource_parameters) { [{"id" => user3.id.to_s}, {"id" => user1.id.to_s}, {"foo" => "bar"}, {"id" => "999_999"}] }

        let(:expected_result_user3) do
          {
            "success" => false,
            "message" => "Access to the resource users/#{user3.id} is forbidden",
            "href"    => "http://www.example.com/api/users/#{user3.id}"
          }
        end

        let(:expected_result_user1) do
          {
            "success" => true,
            "message" => "All sessions revoked successfully for user #{user1.userid}.",
            "href"    => "http://www.example.com/api/users/#{user1.id}"
          }
        end

        let(:expected_result_invalid_id) do
          {
            "success" => false,
            "message" => "Invalid User id  specified",
            "href"    => "http://www.example.com/api/users/"
          }
        end

        let(:expected_result_not_found) do
          {
            "success" => false,
            "message" => "Couldn't find User with 'id'=999999",
            "href"    => "http://www.example.com/api/users/999999"
          }
        end

        let(:expected_results) do
          [expected_result_user3, expected_result_user1, expected_result_invalid_id, expected_result_not_found]
        end

        it "tries to revoke resource users sessions when authenticated user doesn't have access to all users" do
          api_basic_authorize :revoke_user_sessions

          user1.miq_groups << @user.miq_groups.first
          user1.save

          post(api_users_url, :params => {"action" => "revoke_sessions", "resources" => resource_parameters})

          expect(response.parsed_body["results"]).to match_array(expected_results)
        end
      end
    end
  end
end
