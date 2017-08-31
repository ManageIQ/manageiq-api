# rubocop:disable Style/WordArray
RSpec.describe 'GenericObjectDefinitions API' do
  let(:object_def) { FactoryGirl.create(:generic_object_definition, :name => 'foo') }
  let(:object_def2) { FactoryGirl.create(:generic_object_definition, :name => 'foo 2') }
  let(:object_def3) { FactoryGirl.create(:generic_object_definition, :name => 'foo 3') }

  describe 'GET /api/generic_object_definitions' do
    it 'does not list object definitions without an appropriate role' do
      api_basic_authorize

      get(api_generic_object_definitions_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'lists all generic object definitions with an appropriate role' do
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :read, :get)
      object_def_href = api_generic_object_definition_url(nil, object_def.compressed_id)

      get(api_generic_object_definitions_url)

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

      get(api_generic_object_definition_url(nil, object_def.compressed_id))

      expect(response).to have_http_status(:forbidden)
    end

    it 'can query an object definition by its id' do
      api_basic_authorize action_identifier(:generic_object_definitions, :read, :resource_actions, :get)

      get(api_generic_object_definition_url(nil, object_def))

      expected = {
        'id'   => object_def.compressed_id,
        'name' => object_def.name
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can query an object definition by its name' do
      api_basic_authorize action_identifier(:generic_object_definitions, :read, :resource_actions, :get)

      get(api_generic_object_definition_url(nil, object_def.name))

      expected = {
        'id'   => object_def.compressed_id,
        'name' => object_def.name
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'raises a record not found error if no object definition is found' do
      api_basic_authorize action_identifier(:generic_object_definitions, :read, :resource_actions, :get)

      get(api_generic_object_definitions_url('bar'))

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
      post(api_generic_object_definitions_url, :params => object_definition)

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
      post(api_generic_object_definitions_url, :params => request)

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
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :edit)

      request = {
        'action'    => 'edit',
        'resources' => [
          { 'name' => object_def.name, 'resource' => { 'name' => 'updated 1' } },
          { 'id' => object_def2.compressed_id, 'resource' => { 'name' => 'updated 2' }},
          { 'href' => api_generic_object_definition_url(nil, object_def3.compressed_id), 'resource' => { 'name' => 'updated 3' }}
        ]
      }
      post(api_generic_object_definitions_url, :params => request)

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

    it 'can add associations by id, name, or href' do
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :add_associations)

      request = {
        'action'    => 'add_associations',
        'resources' => [
          { 'name' => object_def.name, 'resource' => { 'associations' => { 'association1' => 'AvailabilityZone' } } },
          { 'id' => object_def2.compressed_id, 'resource' => { 'associations' => { 'association2' => 'AvailabilityZone' } }},
          { 'href' => api_generic_object_definition_url(nil, object_def3.compressed_id), 'resource' => { 'associations' => { 'association3' => 'AvailabilityZone' } }}
        ]
      }
      post(api_generic_object_definitions_url, :params => request)

      expected = {
        'results' => a_collection_including(
          a_hash_including('id' => object_def.compressed_id, 'properties' => a_hash_including('associations' => {'association1' => 'AvailabilityZone'})),
          a_hash_including('id' => object_def2.compressed_id, 'properties' => a_hash_including('associations' => {'association2' => 'AvailabilityZone'})),
          a_hash_including('id' => object_def3.compressed_id, 'properties' => a_hash_including('associations' => {'association3' => 'AvailabilityZone'}))
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'cannot add associations without an appropriate role' do
      api_basic_authorize

      post(api_generic_object_definitions_url, :params => { :action => 'add_associations' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can remove associations by id, name, or href' do
      object_def.add_property_association('association1', 'AvailabilityZone')
      object_def2.add_property_association('association2', 'AvailabilityZone')
      object_def3.add_property_association('association3', 'AvailabilityZone')
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :add_associations)

      request = {
        'action'    => 'remove_associations',
        'resources' => [
          { 'name' => object_def.name, 'resource' => { 'associations' => { 'association1' => 'AvailabilityZone' } } },
          { 'id' => object_def2.compressed_id, 'resource' => { 'associations' => { 'association2' => 'AvailabilityZone' } }},
          { 'href' => api_generic_object_definition_url(nil, object_def3.compressed_id), 'resource' => { 'associations' => { 'association3' => 'AvailabilityZone' } }}
        ]
      }
      post(api_generic_object_definitions_url, :params => request)

      expected = {
        'results' => a_collection_including(
          a_hash_including('id' => object_def.compressed_id, 'properties' => a_hash_including('associations' => {})),
          a_hash_including('id' => object_def2.compressed_id, 'properties' => a_hash_including('associations' => {})),
          a_hash_including('id' => object_def3.compressed_id, 'properties' => a_hash_including('associations' => {}))
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'cannot remove associations without an appropriate role' do
      api_basic_authorize

      post(api_generic_object_definitions_url, :params => { :action => 'remove_associations' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can add attributes by id, name, or href' do
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :add_associations)

      request = {
        'action'    => 'add_attributes',
        'resources' => [
          { 'name' => object_def.name, 'resource' => { 'attributes' => { 'attr1' => 'string' } } },
          { 'id' => object_def2.compressed_id, 'resource' => { 'attributes' => { 'attr2' => 'string' } }},
          { 'href' => api_generic_object_definition_url(nil, object_def3.compressed_id), 'resource' => { 'attributes' => { 'attr3' => 'string' } }}
        ]
      }
      post(api_generic_object_definitions_url, :params => request)

      expected = {
        'results' => a_collection_including(
          a_hash_including('id' => object_def.compressed_id, 'properties' => a_hash_including('attributes' => {'attr1' => 'string'})),
          a_hash_including('id' => object_def2.compressed_id, 'properties' => a_hash_including('attributes' => {'attr2' => 'string'})),
          a_hash_including('id' => object_def3.compressed_id, 'properties' => a_hash_including('attributes' => {'attr3' => 'string'}))
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'cannot add attributes without an appropriate role' do
      api_basic_authorize

      post(api_generic_object_definitions_url, :params => { :action => 'add_attributes' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can remove attributes by id, name, or href' do
      object_def.add_property_attribute('attr1', 'string')
      object_def2.add_property_attribute('attr2', 'string')
      object_def3.add_property_attribute('attr3', 'string')
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :add_associations)

      request = {
        'action'    => 'remove_attributes',
        'resources' => [
          { 'name' => object_def.name, 'resource' => { 'attributes' => { 'attr1' => 'string' } } },
          { 'id' => object_def2.compressed_id, 'resource' => { 'attributes' => { 'attr2' => 'string' } }},
          { 'href' => api_generic_object_definition_url(nil, object_def3.compressed_id), 'resource' => { 'attributes' => { 'attr3' => 'string' } }}
        ]
      }
      post(api_generic_object_definitions_url, :params => request)

      expected = {
        'results' => a_collection_including(
          a_hash_including('id' => object_def.compressed_id, 'properties' => a_hash_including('attributes' => {})),
          a_hash_including('id' => object_def2.compressed_id, 'properties' => a_hash_including('attributes' => {})),
          a_hash_including('id' => object_def3.compressed_id, 'properties' => a_hash_including('attributes' => {}))
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'cannot remove attributes without an appropriate role' do
      api_basic_authorize

      post(api_generic_object_definitions_url, :params => { :action => 'remove_attributes' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can add methods by id, name, or href' do
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :add_associations)

      request = {
        'action'    => 'add_methods',
        'resources' => [
          { 'name' => object_def.name, 'resource' => { 'methods' => ['method1'] } },
          { 'id' => object_def2.compressed_id, 'resource' => { 'methods' => ['method2'] }},
          { 'href' => api_generic_object_definition_url(nil, object_def3.compressed_id), 'resource' => { 'methods' => ['method3'] }}
        ]
      }
      post(api_generic_object_definitions_url, :params => request)

      expected = {
        'results' => a_collection_including(
          a_hash_including('id' => object_def.compressed_id, 'properties' => a_hash_including('methods' => ['method1'])),
          a_hash_including('id' => object_def2.compressed_id, 'properties' => a_hash_including('methods' => ['method2'])),
          a_hash_including('id' => object_def3.compressed_id, 'properties' => a_hash_including('methods' => ['method3']))
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'cannot add methods without an appropriate role' do
      api_basic_authorize

      post(api_generic_object_definitions_url, :params => { :action => 'add_methods' })

      expect(response).to have_http_status(:forbidden)
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
      post(api_generic_object_definition_url(nil, object_def.name), :params => request)

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
      post(api_generic_object_definition_url(nil, object_def.compressed_id), :params => request)

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
      post(api_generic_object_definition_url(nil, object_def.compressed_id), :params => request)

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

      post(api_generic_object_definition_url(nil, object_def.name), :params => { :action => 'delete' })

      expect(response).to have_http_status(:ok)
    end

    it 'can delete an object definition by id' do
      api_basic_authorize action_identifier(:generic_object_definitions, :delete)

      post(api_generic_object_definition_url(nil, object_def.compressed_id), :params => { :action => 'delete' })

      expect(response).to have_http_status(:ok)
    end

    it 'will not delete a generic_object_definition if it is in use' do
      api_basic_authorize action_identifier(:generic_object_definitions, :delete, :resource_actions, :delete)
      object_def.create_object(:name => 'foo object')

      post(api_generic_object_definition_url(nil, object_def.name), :params => { :action => 'delete' })

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
      api_basic_authorize collection_action_identifier(:generic_object_definitions, :delete)

      request = {
        'action'    => 'delete',
        'resources' => [
          { 'name' => object_def.name },
          { 'id' => object_def2.compressed_id},
          { 'href' => api_generic_object_definition_url(nil, object_def3.compressed_id)}
        ]
      }
      post(api_generic_object_definitions_url, :params => request)

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

    it 'can add new attributes to the resource' do
      api_basic_authorize action_identifier(:generic_object_definitions, :add_attributes)

      request = {
        'action'   => 'add_attributes',
        'resource' => {
          'attributes' => {
            'added_attribute1' => 'string',
            'added_attribute2' => 'boolean'
          }
        }
      }
      post(api_generic_object_definition_url(nil, object_def.compressed_id), :params => request)

      expected = {
        'attributes' => {
          'added_attribute1' => 'string',
          'added_attribute2' => 'boolean'
        }
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['properties']).to include(expected)
    end

    it 'will raise an error for a bad attribute' do
      api_basic_authorize action_identifier(:generic_object_definitions, :add_attributes)

      request = {
        'action'   => 'add_attributes',
        'resource' => {
          'attributes' => {
            'added_attribute1' => 'bad_val'
          }
        }
      }
      post(api_generic_object_definition_url(nil, object_def.compressed_id), :params => request)

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => a_string_including('Failed to add attributes')
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'can remove property attributes' do
      object_def.add_property_attribute('foo', 'string')
      object_def.add_property_attribute('bar', 'boolean')
      api_basic_authorize action_identifier(:generic_object_definitions, :remove_attributes)

      request = {
        'action'   => 'remove_attributes',
        'resource' => {
          'attributes' => {
            'foo' => 'string'
          }
        }
      }
      post(api_generic_object_definition_url(nil, object_def.compressed_id), :params => request)

      expected = {
        'attributes' => {
          'bar' => 'boolean'
        }
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['properties']).to include(expected)
    end

    it 'can add new methods' do
      api_basic_authorize action_identifier(:generic_object_definitions, :add_methods)

      request = {
        'action'   => 'add_methods',
        'resource' => {
          'methods' => ['foo', 'bar']
        }
      }
      post(api_generic_object_definition_url(nil, object_def.compressed_id), :params => request)

      expected = {
        'methods' => ['foo', 'bar']
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['properties']).to include(expected)
    end

    it 'can remove methods' do
      object_def.add_property_method('foo')
      object_def.add_property_method('bar')
      api_basic_authorize action_identifier(:generic_object_definitions, :remove_methods)

      request = {
        'action'   => 'remove_methods',
        'resource' => {
          'methods' => ['foo']
        }
      }
      post(api_generic_object_definition_url(nil, object_def.compressed_id), :params => request)

      expected = {
        'methods' => ['bar']
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['properties']).to include(expected)
    end

    it 'cannot remove methods without an appropriate role' do
      api_basic_authorize

      post(api_generic_object_definitions_url, :params => { :action => 'remove_methods'})

      expect(response).to have_http_status(:forbidden)
    end

    it 'can add associations' do
      api_basic_authorize action_identifier(:generic_object_definitions, :add_associations)

      request = {
        'action'   => 'add_associations',
        'resource' => {
          'associations' => {
            'az'         => 'AvailabilityZone',
            'chargeback' => 'ChargebackVm'
          }
        }
      }
      post(api_generic_object_definition_url(nil, object_def.compressed_id), :params => request)

      expected = {
        'associations' => {
          'az'         => 'AvailabilityZone',
          'chargeback' => 'ChargebackVm'
        }
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['properties']).to include(expected)
    end

    it 'will raise an error for invalid associations' do
      api_basic_authorize action_identifier(:generic_object_definitions, :add_associations)

      request = {
        'action'   => 'add_associations',
        'resource' => {
          'associations' => {
            'az'         => 'AvailabilityZone',
            'chargeback' => 'bad_type'
          }
        }
      }
      post(api_generic_object_definition_url(nil, object_def.compressed_id), :params => request)

      expected = {
        'error' => a_hash_including(
          'kind'    => 'bad_request',
          'message' => a_string_including('Failed to add attributes')
        )
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'can remove associations' do
      object_def.add_property_association('az', 'AvailabilityZone')
      object_def.add_property_association('chargeback', 'ChargebackVm')
      api_basic_authorize action_identifier(:generic_object_definitions, :remove_associations)

      request = {
        'action'   => 'remove_associations',
        'resource' => {
          'associations' => { 'az' => 'AvailabilityZone' }
        }
      }
      post(api_generic_object_definition_url(nil, object_def.compressed_id), :params => request)

      expected = {
        'associations' => { 'chargeback' => 'ChargebackVm' }
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['properties']).to include(expected)
    end
  end

  describe 'DELETE /api/generic_object_definitions/:id' do
    it 'can delete a generic_object_definition by id' do
      api_basic_authorize action_identifier(:generic_object_definitions, :delete, :resource_actions, :delete)

      delete(api_generic_object_definition_url(nil, object_def.compressed_id))

      expect(response).to have_http_status(:no_content)
    end

    it 'can delete a generic_object_definition by name' do
      api_basic_authorize action_identifier(:generic_object_definitions, :delete, :resource_actions, :delete)

      delete(api_generic_object_definition_url(nil, object_def.name))

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
      put(api_generic_object_definition_url(nil, object_def.name), :params => request)

      expected = {
        'name'        => 'LoadBalancer Updated',
        'description' => 'LoadBalancer description Updated'
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'OPTIONS /api/generic_object_definitions' do
    it 'returns allowed association types and data types' do
      options(api_generic_object_definitions_url)

      expected_data = {'allowed_association_types' => Api::GenericObjectDefinitionsController.allowed_association_types,
                       'allowed_types'             => Api::GenericObjectDefinitionsController.allowed_types}

      expect_options_results(:generic_object_definitions, expected_data)
    end
  end
end
