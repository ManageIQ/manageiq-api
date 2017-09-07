RSpec.describe 'GenericObjects API' do
  let(:object_definition) { FactoryGirl.create(:generic_object_definition, :name => 'object def') }
  let(:vm) { FactoryGirl.create(:vm_amazon) }
  let(:vm2) { FactoryGirl.create(:vm_amazon) }
  let(:service) { FactoryGirl.create(:service) }
  let(:object) { FactoryGirl.create(:generic_object, :name => 'object 1', :generic_object_definition => object_definition) }

  before do
    object_definition.add_property_attribute('widget', 'string')
    object_definition.add_property_attribute('is_something', 'boolean')

    object_definition.add_property_association('services', 'Service')
    object_definition.add_property_association('vms', 'Vm')

    object_definition.add_property_method('method_a')
    object_definition.add_property_method('method_b')
  end

  describe 'GET /api/generic_objects' do
    it 'will return all generic objects' do
      object = FactoryGirl.create(:generic_object, :generic_object_definition => object_definition)
      api_basic_authorize collection_action_identifier(:generic_objects, :read, :get)

      run_get(api_generic_objects_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'generic_objects',
        'resources' => [
          a_hash_including('href' => api_generic_object_url(nil, object.compressed_id))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'allows specifying attributes' do
      object = FactoryGirl.create(:generic_object, :generic_object_definition => object_definition)
      object.add_to_property_association('vms', [vm, vm2])
      object.add_to_property_association('services', service)
      api_basic_authorize collection_action_identifier(:generic_objects, :read, :get)

      run_get(api_generic_objects_url, :expand => :resources, :property_associations => 'vms,services')

      expected = {
        'resources' => [
          a_hash_including(
            'id'                  => object.compressed_id,
            'property_attributes' => {},
            'vms'                 => a_collection_including(a_hash_including('id' => vm.compressed_id), a_hash_including('id' => vm2.compressed_id)),
            'services'            => [a_hash_including('id' => service.compressed_id)]
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'GET /api/generic_objects/:id' do
    before do
      object.widget = 'a widget string'
      object.is_something = true
      object.save!

      object.add_to_property_association('vms', [vm, vm2])
      object.add_to_property_association('services', service)
    end

    it 'returns a generic object with property_attributes' do
      api_basic_authorize action_identifier(:generic_objects, :read, :resource_actions, :get)

      run_get(api_generic_object_url(nil, object.compressed_id))

      expected = {
        'name'                => 'object 1',
        'property_attributes' => { 'widget' => 'a widget string', 'is_something' => true }
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'allows specification of property_associations and returns them accordingly' do
      api_basic_authorize action_identifier(:generic_objects, :read, :resource_actions, :get)

      run_get(api_generic_object_url(nil, object.compressed_id), :property_associations => 'vms,services')

      # TODO: add test to ensure the hrefs correctly align with the collection
      expected = {
        'name'                => 'object 1',
        'property_attributes' => { 'widget' => 'a widget string', 'is_something' => true },
        'services'            => a_collection_containing_exactly(a_hash_including('id' => service.compressed_id)),
        'vms'                 => a_collection_containing_exactly(
          a_hash_including('id' => vm.compressed_id),
          a_hash_including('id' => vm2.compressed_id)
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/generic_objects' do
    it 'does not allow creation of a generic object without appropriate role' do
      api_basic_authorize

      run_post(api_generic_objects_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'can create a new generic object' do
      api_basic_authorize collection_action_identifier(:generic_objects, :create)

      generic_object = {
        'generic_object_definition' => { 'href' => api_generic_object_definition_url(nil, object_definition.compressed_id) },
        'name'                      => 'go_name1',
        'uid'                       => 'optional_uid',
        'property_attributes'       => {
          'widget'       => 'widget value',
          'is_something' => false
        },
        'associations'              => {
          'vms'      => [
            { 'href' => api_vm_url(nil, vm.compressed_id) },
            { 'href' => api_vm_url(nil, vm2.compressed_id) }
          ],
          'services' => [
            { 'href' => api_service_url(nil, service.compressed_id) }
          ]
        }
      }
      run_post(api_generic_objects_url, generic_object)

      expected = {
        'results' => [
          a_hash_including('name'                         => 'go_name1',
                           'uid'                          => 'optional_uid',
                           'generic_object_definition_id' => object_definition.compressed_id)
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
