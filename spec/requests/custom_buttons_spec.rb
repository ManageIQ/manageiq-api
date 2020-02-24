RSpec.describe 'CustomButtons API' do
  let(:object_def) { FactoryBot.create(:generic_object_definition, :name => 'foo') }
  let(:cb) { FactoryBot.create(:custom_button, :name => 'custom_button', :applies_to_class => 'GenericObjectDefinition', :applies_to_id => object_def.id) }

  describe 'GET /api/custom_buttons' do
    before { cb }

    context 'without an appropriate role' do
      it 'does not list custom buttons' do
        api_basic_authorize

        get(api_custom_buttons_url)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with an appropriate role' do
      before { api_basic_authorize collection_action_identifier(:custom_buttons, :read, :get) }

      it 'lists all custom buttons' do

        get(api_custom_buttons_url)

        expected = {
          'count'     => 1,
          'subcount'  => 1,
          'name'      => 'custom_buttons',
          'resources' => [
            hash_including('href' => api_custom_button_url(nil, cb))
          ]
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end
    end
  end

  describe 'GET /api/custom_buttons/:id' do
    context 'without an appropriate role' do
      it 'does not let you query a custom button' do
        api_basic_authorize

        get(api_custom_button_url(nil, cb))

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns the correct actions' do
        api_basic_authorize(collection_action_identifier(:custom_buttons, :edit),
                            action_identifier(:custom_buttons, :read, :resource_actions, :get))

        get(api_custom_button_url(nil, cb))

        expected = {
          'actions' => [
            a_hash_including('name' => 'edit', 'method' => 'post'),
            a_hash_including('name' => 'edit', 'method' => 'patch'),
            a_hash_including('name' => 'edit', 'method' => 'put')
          ]
        }
        expect(response.parsed_body).to include(expected)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with an appropriate role' do
      before { api_basic_authorize action_identifier(:custom_buttons, :read, :resource_actions, :get) }

      it 'can query a custom button by its id' do
        get(api_custom_button_url(nil, cb))

        expected = {
          'id'   => cb.id.to_s,
          'name' => "custom_button"
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(expected)
      end

      context "with an object derived from a virtual attribute" do
        before do
          cb.resource_action = FactoryBot.create(:resource_action)
        end

        it 'does not include an href for that object, as it is not a valid collection' do
          get(api_custom_button_url(nil, cb, :attributes => 'resource_action'))

          expect(response.parsed_body['resource_action']).to be_present
          expect(response.parsed_body['resource_action']).to_not include('href')
        end
      end
    end
  end

  describe 'POST /api/custom_buttons' do
    it 'can create a new custom button' do
      api_basic_authorize collection_action_identifier(:custom_buttons, :create)

      cb_rec = {
        'name'             => 'Generic Object Custom Button',
        'description'      => 'Generic Object Custom Button description',
        'applies_to_class' => 'GenericObjectDefinition',
        'uri_attributes'   => {:request => "automate_method"},
        'options'          => {
          'button_icon'  => 'ff ff-view-expanded',
          'button_color' => '#4727ff',
          'display'      => true,
        },
        'resource_action'  => {
          'ae_namespace' => 'SYSTEM',
          'ae_class'     => 'PROCESS'
        },
        'visibility'       => {'roles' => ['_ALL_']}
      }
      post(api_custom_buttons_url, :params => cb_rec)

      expect(response).to have_http_status(:ok)
      custom_button = CustomButton.find(response.parsed_body['results'].first["id"])
      expect(custom_button.options[:button_icon]).to eq("ff ff-view-expanded")
      expect(custom_button.visibility['roles']).to eq(['_ALL_'])
      expect(response.parsed_body['results'].first).to include(cb_rec.except('resource_action', 'uri_attributes'))
    end

    it 'can edit custom buttons by id' do
      api_basic_authorize collection_action_identifier(:custom_buttons, :edit)

      request = {
        'action'    => 'edit',
        'resources' => [
          {'id' => cb.id.to_s, 'resource' => {'name' => 'updated 1', 'resource_action' => {'ae_namespace' => 'SYSTEM2', :ae_attributes => {"attribute" => "is present"}}, 'visibility' => {'roles' => ['_ALL_']}}},
        ]
      }
      post(api_custom_buttons_url, :params => request)

      expected = {
        'results' => a_collection_including(
          a_hash_including('id' => cb.id.to_s, 'name' => 'updated 1', 'visibility' => {'roles' => ['_ALL_']}),
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
      expect(cb.reload.visibility[:roles]).to eq(['_ALL_'])
      expect(cb.reload.resource_action.ae_attributes).to include("attribute" => "is present")
    end
  end

  describe 'POST /api/custom_buttons/:id' do
    it 'can update a custom buttons by id' do
      api_basic_authorize action_identifier(:custom_buttons, :edit)

      request = {
        'action'      => 'edit',
        'name'        => 'Generic Object Custom Button Updated',
        'description' => 'Generic Object Custom Button description Updated',
      }
      post(api_custom_button_url(nil, cb), :params => request)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(request.except('action'))
    end

    it 'can delete a custom button by id' do
      api_basic_authorize action_identifier(:custom_buttons, :delete)

      post(api_custom_button_url(nil, cb), :params => { :action => 'delete' })

      expect(response).to have_http_status(:ok)
    end

    it 'can delete custom button in bulk by id' do
      api_basic_authorize collection_action_identifier(:custom_buttons, :delete)

      request = {
        'action'    => 'delete',
        'resources' => [
          { 'id' => cb.id.to_s}
        ]
      }
      post(api_custom_buttons_url, :params => request)

      expected = {
        'results' => a_collection_including(
          a_hash_including('success' => true, 'message' => "custom_buttons id: #{cb.id} deleting")
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'DELETE /api/custom_buttons/:id' do
    it 'can delete a custom button by id' do
      api_basic_authorize action_identifier(:custom_buttons, :delete, :resource_actions, :delete)

      delete(api_custom_button_url(nil, cb))

      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'PUT /api/custom_buttons/:id' do
    it 'can edit a custom button' do
      api_basic_authorize action_identifier(:custom_buttons, :edit)

      request = {
        'name'        => 'Generic Object Custom Button Updated',
        'description' => 'Generic Object Custom Button Description Updated',
      }
      put(api_custom_button_url(nil, cb), :params => request)

      expected = {
        'name'        => 'Generic Object Custom Button Updated',
        'description' => 'Generic Object Custom Button Description Updated',
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'PATCH /api/custom_buttons/:id' do
    it 'can edit a custom button' do
      api_basic_authorize action_identifier(:custom_buttons, :edit)

      request = [
        {
          'action' => 'edit',
          'path'   => 'name',
          'value'  => 'Generic Object Custom Button Updated',
        },
        {
          'action' => 'edit',
          'path'   => 'description',
          'value'  => 'Generic Object Custom Button Description Updated',
        }
      ]
      patch(api_custom_button_url(nil, cb), :params => request)

      expected = {
        'name'        => 'Generic Object Custom Button Updated',
        'description' => 'Generic Object Custom Button Description Updated',
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'OPTIONS /api/custom_buttons' do
    it 'returns custom_button_types' do
      options(api_custom_buttons_url)

      expected_data = {'custom_button_types' => CustomButton::TYPES}

      expect_options_results(:custom_buttons, expected_data)
    end
  end
end
