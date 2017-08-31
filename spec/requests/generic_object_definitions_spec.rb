# rubocop:disable Style/WordArray
RSpec.describe 'GenericObjectDefinitions API' do
  let(:object_def) { FactoryGirl.create(:generic_object_definition, :name => 'foo') }

  describe 'GET /api/generic_object_definitions' do
    it 'does not list object definitions without an appropriate role' do
      api_basic_authorize

      run_get(generic_object_definitions_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'lists all generic object definitions with an appropriate role' do
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :read, :get)
      object_def_href = generic_object_definitions_url(object_def.compressed_id)

      run_get(generic_object_definitions_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'generic_object_definitions',
        'resources' => [
          hash_including('href' => a_string_matching(object_def_href))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'GET /api/generic_object_definitions/:id' do
    it 'does not let you query object definitions without an appropriate role' do
      api_basic_authorize

      run_get(generic_object_definitions_url(object_def.compressed_id))

      expect(response).to have_http_status(:forbidden)
    end

    it 'can query an object definition by its id' do
      api_basic_authorize action_identifier(:generic_object_definitions, :read, :resource_actions, :get)

      run_get(generic_object_definitions_url(object_def.id))

      expected = {
        'id'   => object_def.compressed_id,
        'name' => object_def.name
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can query an object definition by its name' do
      api_basic_authorize action_identifier(:generic_object_definitions, :read, :resource_actions, :get)

      run_get(generic_object_definitions_url(object_def.name))

      expected = {
        'id'   => object_def.compressed_id,
        'name' => object_def.name
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'raises a record not found error if no object definition is found' do
      api_basic_authorize action_identifier(:generic_object_definitions, :read, :resource_actions, :get)

      run_get(generic_object_definitions_url('bar'))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/generic_object_definitions' do
    it 'can create a new generic_object_definition' do
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :create)

      object_definition = {
        'name'        => 'LoadBalancer',
        'description' => 'LoadBalancer description',
        'properties'  => {
          'attributes'   => {
            'address'      => 'string',
            'last_restart' => 'datetime'
          },
          'associations' => {
            'vms'      => 'Vm',
            'services' => 'Service'
          },
          'methods'      => [
            'add_vm',
            'remove_vm'
          ]
        }
      }
      run_post(generic_object_definitions_url, object_definition)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['results'].first).to include(object_definition)
    end

    it 'cannot create an invalid generic_object_definition' do
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :create)

      request = {
        'name'        => 'foo',
        'description' => 'LoadBalancer description',
        'properties'  => {
          'attributes' => {
            'last_restart' => 'date'
          }
        }
      }
      run_post(generic_object_definitions_url, request)

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => a_string_including('Failed to create new generic object definition - Validation failed')
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'can edit generic_object_definitions by id, name, or href' do
      object_def2 = FactoryGirl.create(:generic_object_definition, :name => 'foo 2')
      object_def3 = FactoryGirl.create(:generic_object_definition, :name => 'foo 3')
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :edit)

      request = {
        'action'    => 'edit',
        'resources' => [
          { 'name' => object_def.name, 'resource' => { 'name' => 'updated 1' } },
          { 'id' => object_def2.compressed_id, 'resource' => { 'name' => 'updated 2' }},
          { 'href' => generic_object_definitions_url(object_def3.compressed_id), 'resource' => { 'name' => 'updated 3' }}
        ]
      }
      run_post(generic_object_definitions_url, request)

      expected = {
        'results' => a_collection_including(
          a_hash_including('id' => object_def.compressed_id, 'name' => 'updated 1'),
          a_hash_including('id' => object_def2.compressed_id, 'name' => 'updated 2'),
          a_hash_including('id' => object_def3.compressed_id, 'name' => 'updated 3')
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/generic_object_definitions/:id' do
    it 'can update an object definition by name' do
      api_basic_authorize action_identifier(:generic_object_definitions, :edit)

      request = {
        'action'      => 'edit',
        'name'        => 'LoadBalancer Updated',
        'description' => 'LoadBalancer description Updated',
        'properties'  => {
          'attributes'   => {
            'last_updated' => 'string',
          },
          'associations' => {
            'vms'      => 'Vm',
            'services' => 'Service'
          },
          'methods'      => [
            'add_vm',
            'remove_vm',
            'new_method'
          ]
        }
      }
      run_post(generic_object_definitions_url(object_def.name), request)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(request.except('action'))
    end

    it 'can update an object definition by id' do
      api_basic_authorize action_identifier(:generic_object_definitions, :edit)

      request = {
        'action'      => 'edit',
        'name'        => 'LoadBalancer Updated',
        'description' => 'LoadBalancer description Updated',
        'properties'  => {
          'attributes'   => {
            'last_updated' => 'string',
          },
          'associations' => {
            'vms'      => 'Vm',
            'services' => 'Service'
          },
          'methods'      => [
            'add_vm',
            'remove_vm',
            'new_method'
          ]
        }
      }
      run_post(generic_object_definitions_url(object_def.compressed_id), request)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(request.except('action'))
    end

    it 'cannot update an object with bad data' do
      api_basic_authorize action_identifier(:generic_object_definitions, :edit)

      request = {
        'action'     => 'edit',
        'properties' => {
          'attributes' => {
            'last_updated' => 'date',
          }
        }
      }
      run_post(generic_object_definitions_url(object_def.compressed_id), request)

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => a_string_including('Failed to update generic object definition - Validation failed')
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'can delete an object definition by name' do
      api_basic_authorize action_identifier(:generic_object_definitions, :delete)

      run_post(generic_object_definitions_url(object_def.name), :action => 'delete')

      expect(response).to have_http_status(:ok)
    end

    it 'can delete an object definition by id' do
      api_basic_authorize action_identifier(:generic_object_definitions, :delete)

      run_post(generic_object_definitions_url(object_def.compressed_id), :action => 'delete')

      expect(response).to have_http_status(:ok)
    end

    it 'will not delete a generic_object_definition if it is in use' do
      api_basic_authorize action_identifier(:generic_object_definitions, :delete, :resource_actions, :delete)
      object_def.create_object(:name => 'foo object')

      run_post(generic_object_definitions_url(object_def.name), :action => 'delete')

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => a_string_including('Failed to delete generic object definition')
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'can delete generic_object_definition in bulk by name, id, or href' do
      object_def2 = FactoryGirl.create(:generic_object_definition, :name => 'foo 2')
      object_def3 = FactoryGirl.create(:generic_object_definition, :name => 'foo 3')
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :delete)

      request = {
        'action'    => 'delete',
        'resources' => [
          { 'name' => object_def.name },
          { 'id' => object_def2.compressed_id},
          { 'href' => generic_object_definitions_url(object_def3.compressed_id)}
        ]
      }
      run_post(generic_object_definitions_url, request)

      expected = {
        'results' => a_collection_including(
          a_hash_including('id' => object_def.compressed_id),
          a_hash_including('id' => object_def2.compressed_id),
          a_hash_including('id' => object_def3.compressed_id)
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'DELETE /api/generic_object_definitions/:id' do
    it 'can delete a generic_object_definition by id' do
      api_basic_authorize action_identifier(:generic_object_definitions, :delete, :resource_actions, :delete)

      run_delete(generic_object_definitions_url(object_def.compressed_id))

      expect(response).to have_http_status(:no_content)
    end

    it 'can delete a generic_object_definition by name' do
      api_basic_authorize action_identifier(:generic_object_definitions, :delete, :resource_actions, :delete)

      run_delete(generic_object_definitions_url(object_def.name))

      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'PUT /api/generic_object_definitions/:id' do
    it 'can edit a generic object definition' do
      api_basic_authorize action_identifier(:generic_object_definitions, :edit)

      request = {
        'name'        => 'LoadBalancer Updated',
        'description' => 'LoadBalancer description Updated'
      }
      run_put(generic_object_definitions_url(object_def.name), request)

      expected = {
        'name'        => 'LoadBalancer Updated',
        'description' => 'LoadBalancer description Updated'
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
