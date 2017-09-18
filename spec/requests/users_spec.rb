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

  let(:tenant1)  { FactoryGirl.create(:tenant, :name => "Tenant1") }
  let(:role1)    { FactoryGirl.create(:miq_user_role) }
  let(:group1)   { FactoryGirl.create(:miq_group, :description => "Group1", :role => role1, :tenant => tenant1) }

  let(:role2)    { FactoryGirl.create(:miq_user_role) }
  let(:group2)   { FactoryGirl.create(:miq_group, :description => "Group2", :role => role2, :tenant => tenant1) }

  let(:sample_user1) { {:userid => "user1", :name => "User1", :password => "password1", :group => {"id" => group1.id}} }
  let(:sample_user2) { {:userid => "user2", :name => "User2", :password => "password2", :group => {"id" => group2.id}} }

  let(:user1) { FactoryGirl.create(:user, sample_user1.except(:group).merge(:miq_groups => [group1])) }
  let(:user2) { FactoryGirl.create(:user, sample_user2.except(:group).merge(:miq_groups => [group2])) }

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
      user = FactoryGirl.create(:user)

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

    it "cannot change another user's password" do
      api_basic_authorize
      user = FactoryGirl.create(:user)

      expect do
        post api_user_url(nil, user), :params => gen_request(:edit, :password => "new_password")
      end.not_to change { user.reload.password_digest }

      expect(response).to have_http_status(:forbidden)
    end

    it "cannot change another user's settings" do
      api_basic_authorize
      user = FactoryGirl.create(:user, :settings => {:locale => "en"})

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
  end

  describe "users edit" do
    it "allows for setting of multiple miq_groups" do
      group3 = FactoryGirl.create(:miq_group)
      api_basic_authorize collection_action_identifier(:users, :edit)

      request = {
        "action"    => "edit",
        "resources" => [{
          "href"       => api_user_url(nil, user1),
          "miq_groups" => [
            { "id" => group2.id.to_s },
            { "href" => api_group_url(nil, group3) }
          ]
        }]
      }
      post(api_users_url, :params => request)

      expect(response).to have_http_status(:ok)
      expect(user1.reload.miq_groups).to match_array([group2, group3])
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

    it "can set a user's current group" do
      api_basic_authorize collection_action_identifier(:users, :edit)
      user1.miq_groups << group2

      post(api_user_url(nil, user1), :params => gen_request(:edit, "current_group" => { "href" => api_group_url(nil, group2) }))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["current_group_id"]).to eq(group2.id.to_s)
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

      expect_single_action_result(:success => true, :message => "deleting", :href => api_user_url(nil, user1))
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
    it "can list a user's tags" do
      user = FactoryGirl.create(:user)
      FactoryGirl.create(:classification_department_with_tags)
      Classification.classify(user, "department", "finance")
      api_basic_authorize

      get(api_user_tags_url(nil, user))

      expect(response.parsed_body).to include("subcount" => 1)
      expect(response).to have_http_status(:ok)
    end

    it "can assign a tag to a user" do
      user = FactoryGirl.create(:user)
      FactoryGirl.create(:classification_department_with_tags)
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
      user = FactoryGirl.create(:user)
      FactoryGirl.create(:classification_department_with_tags)
      Classification.classify(user, "department", "finance")
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
  end
end
