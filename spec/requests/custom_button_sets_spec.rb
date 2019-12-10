RSpec.describe 'CustomButtonSets API' do
  let(:cb_set) { FactoryBot.create(:custom_button_set, :name => 'custom_button_set') }
  let(:cb_set2) { FactoryBot.create(:custom_button_set, :name => 'custom_button_set2') }

  describe 'GET /api/custom_button_sets' do
    it 'does not list custom button sets without an appropriate role' do
      api_basic_authorize

      get(api_custom_button_sets_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'lists all custom button sets with an appropriate role' do
      api_basic_authorize collection_action_identifier(:custom_button_sets, :read, :get)
      cb_set_href = api_custom_button_set_url(nil, cb_set)

      get(api_custom_button_sets_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'custom_button_sets',
        'resources' => [
          hash_including('href' => cb_set_href)
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'GET /api/custom_button_sets/:id' do
    it 'does not let you query custom button sets without an appropriate role' do
      api_basic_authorize

      get(api_custom_button_set_url(nil, cb_set))

      expect(response).to have_http_status(:forbidden)
    end

    it 'can query a custom button set by its id' do
      api_basic_authorize action_identifier(:custom_button_sets, :read, :resource_actions, :get)

      get(api_custom_button_set_url(nil, cb_set))

      expected = {
        'id'   => cb_set.id.to_s,
        'name' => "custom_button_set"
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/custom_button_sets' do
    it 'can create a new custom button set' do
      api_basic_authorize collection_action_identifier(:custom_button_sets, :create)

      cb_set_rec = {
        'name'        => 'Generic Object Custom Button Group',
        'description' => 'Generic Object Custom Button Group description',
        'set_data'    => {
          'button_icon'      => 'ff ff-view-expanded',
          'button_color'     => '#4727ff',
          'display'          => true,
          'applies_to_class' => 'GenericObjectDefinition',
          'applies_to_id'    => '10000000000050',
        }
      }
      post(api_custom_button_sets_url, :params => cb_set_rec)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['results'].first).to match(
        hash_including(
          'name'        => 'Generic Object Custom Button Group',
          'description' => 'Generic Object Custom Button Group description',
          'set_data'    => hash_including(
            'button_icon'      => 'ff ff-view-expanded',
            'button_color'     => '#4727ff',
            'display'          => true,
            'applies_to_class' => 'GenericObjectDefinition',
            'applies_to_id'    => '10000000000050',
          )
        )
      )
      custom_button_set = CustomButtonSet.find(response.parsed_body['results'].first["id"])
      expect(custom_button_set.set_data[:button_icon]).to eq("ff ff-view-expanded")
    end

    it 'can edit custom button sets by id' do
      api_basic_authorize collection_action_identifier(:custom_button_sets, :edit)

      request = {
        'action'    => 'edit',
        'resources' => [
          { 'id' => cb_set.id.to_s, 'name' => 'updated 1', 'set_data' => {'button_icon' => 'ff ff-closed'} },
        ]
      }
      post(api_custom_button_sets_url, :params => request)

      expected = {
        'results' => a_collection_including(
          a_hash_including('id' => cb_set.id.to_s, 'name' => 'updated 1'),
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
      expect(cb_set.reload.set_data[:button_icon]).to eq("ff ff-closed")
    end
  end

  describe 'POST /api/custom_button_sets/:id' do
    it 'can update a custom button set by id' do
      api_basic_authorize action_identifier(:custom_button_sets, :edit)

      request = {
        'action'      => 'edit',
        'name'        => 'Generic Object Custom Button set Updated',
        'description' => 'Generic Object Custom Button set description Updated',
      }
      post(api_custom_button_set_url(nil, cb_set), :params => request)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(request.except('action'))
    end

    it 'can delete a custom button set by id' do
      api_basic_authorize action_identifier(:custom_button_sets, :delete)

      post(api_custom_button_set_url(nil, cb_set), :params => { :action => 'delete' })

      expect(response).to have_http_status(:ok)
    end

    it 'can delete custom button set in bulk by id' do
      api_basic_authorize collection_action_identifier(:custom_button_sets, :delete)

      request = {
        'action'    => 'delete',
        'resources' => [
          { 'id' => cb_set.id.to_s},
          { 'id' => cb_set2.id.to_s},
        ]
      }
      post(api_custom_button_sets_url, :params => request)

      expected = {
        'results' => a_collection_including(
          a_hash_including('success' => true, 'message' => "custom_button_sets id: #{cb_set.id} deleting"),
          a_hash_including('success' => true, 'message' => "custom_button_sets id: #{cb_set2.id} deleting"),
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'DELETE /api/custom_button_sets/:id' do
    it 'can delete a custom button set by id' do
      api_basic_authorize action_identifier(:custom_button_sets, :delete, :resource_actions, :delete)

      delete(api_custom_button_set_url(nil, cb_set))

      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'PUT /api/custom_button_sets/:id' do
    it 'can edit a custom button set' do
      api_basic_authorize action_identifier(:custom_button_sets, :edit)

      request = {
        'name'        => 'Generic Object Custom Button Set Updated',
        'description' => 'Generic Object Custom Button Set Description Updated',
      }
      put(api_custom_button_set_url(nil, cb_set), :params => request)

      expected = {
        'name'        => 'Generic Object Custom Button Set Updated',
        'description' => 'Generic Object Custom Button Set Description Updated',
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'PATCH /api/custom_button_sets/:id' do
    it 'can edit a custom button set' do
      api_basic_authorize action_identifier(:custom_button_sets, :edit)

      request = [
        {
          'action' => 'edit',
          'path'   => 'name',
          'value'  => 'Generic Object Custom Button Set Updated',
        },
        {
          'action' => 'edit',
          'path'   => 'description',
          'value'  => 'Generic Object Custom Button Set Description Updated',
        }
      ]
      patch(api_custom_button_set_url(nil, cb_set), :params => request)

      expected = {
        'name'        => 'Generic Object Custom Button Set Updated',
        'description' => 'Generic Object Custom Button Set Description Updated',
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
