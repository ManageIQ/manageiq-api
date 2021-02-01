RSpec.describe 'TimeProfiles API' do
  let!(:time_profile) { FactoryBot.create(:time_profile) }

  describe 'GET /api/time_profiles' do
    let(:url) { api_time_profiles_url }

    it 'lists all time profiles images with an appropriate role' do
      api_basic_authorize collection_action_identifier(:time_profiles, :read, :get)
      get(url)
      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'time_profiles',
        'resources' => [
          hash_including('href' => api_time_profile_url(nil, time_profile))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/time_profiles/:id' do
    let(:url) { api_time_profile_url(nil, time_profile) }

    it 'will show a time profile with an appropriate role' do
      api_basic_authorize action_identifier(:time_profiles, :read, :resource_actions, :get)
      get(url)
      expect(response.parsed_body).to include('href' => api_time_profile_url(nil, time_profile))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access without an appropriate role' do
      api_basic_authorize
      get(url)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/time_profiles' do
    it 'forbids creating a time profile without an appropriate role' do
      api_basic_authorize
      post(api_time_profiles_url, :params => {:action => 'create'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids updating a time profile without an appropriate role' do
      api_basic_authorize
      post(api_time_profiles_url, :params => {:action => 'edit'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids deleting a time profile without an appropriate role' do
      api_basic_authorize
      post(api_time_profiles_url, :params => {:action => 'delete'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'creates a time profile with an appropriate role' do
      params = {
        "description"          => "test1",
        "profile_type"         => "user",
        "profile_key"          => "some_user",
        "rollup_daily_metrics" => true
      }
      api_basic_authorize collection_action_identifier(:time_profiles, :create)

      post(api_time_profiles_url, :params => params)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["results"].first).to include(params)
    end

    it 'updates a time profile with an appropriate role' do
      api_basic_authorize collection_action_identifier(:time_profiles, :edit)

      post(api_time_profiles_url, :params => gen_request(:edit, 'id' => time_profile.id, 'description' => 'description updated'))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["results"].first).to include('href' => api_time_profile_url(nil, time_profile))
      expect(time_profile.reload.description).to eq('description updated')
    end

    it 'deletes a time profile with an appropriate role' do
      api_basic_authorize collection_action_identifier(:time_profiles, :delete)

      post(api_time_profiles_url, :params => gen_request(:delete, 'id' => time_profile.id, 'href' => api_time_profile_url(nil, time_profile)))

      expect(response).to have_http_status(:ok)
      expect(TimeProfile.exists?(time_profile.id)).to be false
    end
  end

  describe 'POST /api/time_profiles/:id' do
    it 'forbids updating a time profile without an appropriate role' do
      api_basic_authorize
      post(api_time_profile_url(nil, time_profile), :params => {:action => 'edit', :description => 'description updated'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids deleting a time profile without an appropriate role' do
      api_basic_authorize
      post(api_time_profile_url(nil, time_profile), :params => {:action => 'delete'})
      expect(response).to have_http_status(:forbidden)
    end

    it 'updates a time profile with an appropriate role' do
      api_basic_authorize collection_action_identifier(:time_profiles, :edit)

      post(api_time_profile_url(nil, time_profile), :params => {:action => 'edit', :description => 'description updated'})

      expect(time_profile.reload.description).to eq('description updated')
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('href' => api_time_profile_url(nil, time_profile))
    end

    it 'deletes a time profile with an appropriate role' do
      api_basic_authorize collection_action_identifier(:time_profiles, :delete)

      expect do
        post(api_time_profile_url(nil, time_profile), :params => {:action => 'delete'})
      end.to change(TimeProfile, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PUT /api/time_profiles/:id' do
    it 'updates a time profile with an appropriate role' do
      api_basic_authorize(action_identifier(:time_profiles, :edit))
      put(api_time_profile_url(nil, time_profile), :params => {:description => 'description updated'})
      expect(response).to have_http_status(:ok)
      expect(time_profile.reload.description).to eq('description updated')
    end

    it 'forbids updating a time profile without an appropriate role' do
      api_basic_authorize
      put(api_time_profile_url(nil, time_profile), :params => {:description => 'description updated'})
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PATCH /api/time_profiles/:id' do
    it 'updates a time profile with an appropriate role' do
      api_basic_authorize(action_identifier(:time_profiles, :edit))
      patch(api_time_profile_url(nil, time_profile), :params => {:description => 'description updated'})
      expect(response).to have_http_status(:ok)
      expect(time_profile.reload.description).to eq('description updated')
    end

    it 'forbids updating a time profile without an appropriate role' do
      api_basic_authorize
      patch(api_time_profile_url(nil, time_profile), :params => {:description => 'description updated'})
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/time_profiles/:id' do
    it "deletes a time profile with an appropriate role" do
      api_basic_authorize(action_identifier(:time_profiles, :delete))
      delete(api_time_profile_url(nil, time_profile))
      expect(response).to have_http_status(:no_content)
    end

    it 'forbids deleting a time profile without an appropriate role' do
      api_basic_authorize
      delete(api_time_profile_url(nil, time_profile))
      expect(response).to have_http_status(:forbidden)
    end
  end
end
